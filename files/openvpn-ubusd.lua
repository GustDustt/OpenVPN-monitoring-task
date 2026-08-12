#!/usr/bin/env lua

-- Nuolat veikiantis daemon: registruoja atskirą ubus objektą
-- "openvpn.<server_name>" kiekvienam ijungtam OpenVPN serveriui su
-- management. Rasyta kaip daemon.

local uci = require("uci").cursor()
local ubus = require("ubus")
local uloop = require("uloop")

local function exec_mgt_cmd(server_cfg, cmd)
    local nc_cmd
    if server_cfg.type == "ip" then
        nc_cmd = string.format("echo '%s' | nc %s %s", cmd, server_cfg.ip, server_cfg.port)
    else
        nc_cmd = string.format("echo '%s' | nc -U %s", cmd, server_cfg.path)
    end

    local handle = io.popen(nc_cmd)
    local response = handle:read("*a")
    handle:close()
    return response
end

local function get_users(server_cfg)
    local output = exec_mgt_cmd(server_cfg, "status")
    local clients = {}
    local in_client_list = false

    for line in string.gmatch(output, "[^\r\n]+") do
        if string.find(line, "OpenVPN CLIENT LIST") then
            in_client_list = true
        elseif string.find(line, "ROUTING TABLE") then
            in_client_list = false
        end

        if in_client_list then
            local name, real_ip, rx, tx, since = string.match(line, "([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)")
            if name and name ~= "Common Name" and name ~= "Updated" then
                table.insert(clients, {
                    username = name,
                    real_address = real_ip,
                    bytes_received = tonumber(rx),
                    bytes_sent = tonumber(tx),
                    connected_since = since
                })
            end
        end
    end
    return { users = clients }
end

local function disconnect_user(server_cfg, username)
    if not username or username == "" then
        return { success = false, error = "Missing username parameter" }
    end

    local response = exec_mgt_cmd(server_cfg, "kill " .. username)
    if string.find(response, "SUCCESS") or string.find(response, "Killing") then
        return { success = true, message = "User " .. username .. " disconnected." }
    else
        return { success = false, error = "Failed to disconnect user. " .. response }
    end
end

local function get_active_servers()
    local servers = {}
    uci:foreach("openvpn", "openvpn", function(s)
        if s.enabled == "1" or s.enabled == "true" then
            local mgt = s.management
            if mgt then
                local ip, port = string.match(mgt, "([%d%.]+)%s+(%d+)")
                if ip and port then
                    servers[s[".name"]] = { type = "ip", ip = ip, port = port }
                else
                    servers[s[".name"]] = { type = "socket", path = mgt }
                end
            end
        end
    end)
    return servers
end

uloop.init()

local conn = ubus.connect()
if not conn then
    error("Nepavyko prisijungti prie ubusd")
end

local servers = get_active_servers()
local objects = {}

for sname, server_cfg in pairs(servers) do
    objects["openvpn." .. sname] = {
        get_users = {
            function(req)
                conn:reply(req, get_users(server_cfg))
            end, {}
        },
        disconnect_user = {
            function(req, msg)
                local username = msg and msg.username
                conn:reply(req, disconnect_user(server_cfg, username))
            end, { username = ubus.STRING }
        }
    }
end

conn:add(objects)

uloop.run()
