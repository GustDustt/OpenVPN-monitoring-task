local ConfigService = require("api/ConfigService")
local ubus = require("ubus")

local OpenVpnApi = ConfigService:new({
    delete = false,
    create = false,
    general_section = "openvpn"
})

local Server = OpenVpnApi:section("openvpn", "openvpn")
Server:make_primary()

local opt_disconnect = Server:option("disconnect_client")

function opt_disconnect:validate(value)
    return true
end

function opt_disconnect:get()
    return ""
end

function opt_disconnect:set(value)
    if value and type(value) == "string" and value ~= "" then
        local conn = ubus.connect()
        if conn then
            local object_name = "openvpn." .. self.sid
            
            conn:call(object_name, "disconnect_user", { username = value })
            conn:close()
        end
    end
end

function OpenVpnApi:GET_after_data_hook(data)
    if not data.id then
        return
    end

    local conn = ubus.connect()

    if not conn then
        data.is_running = false
        data.connected_users = {}
        data.client_count = 0
        return
    end

    local running = false
    local users = {}
    local object_name = "openvpn." .. data.id
    
    local result = conn:call(object_name, "get_users", {})

    if result and result.users then
        running = true
        users = result.users
    end

    conn:close()

    data.is_running = running
    data.client_count = #users
    data.connected_users = users
end

return OpenVpnApi