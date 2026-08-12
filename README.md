## Ubus pusė - kaip pasitikrinti rankiniu budu

Idiegus paketa router'yje, galima tiesiog:

```sh
ubus list | grep openvpn
```

turetumet pamatyti kazka panasaus i `openvpn.server_1`, jeigu tas serveris ijungtas ir turi `management` parametra config faile.

Gauti klientu sarasa:

```sh
ubus call openvpn.server_1 get_users
```

Atjungti vartotoja:

```sh
ubus call openvpn.server_1 disconnect_user '{"username":"client1"}'
```

Jeigu router'yje veikia keli serveriai vienu metu, kiekvienas turi savo atskira ubus objekta - taip patenkinamas reikalavimas is uzduoties, kad kiekvienam serveriui butu atskiras objektas.

## API pusė (Postman ar kitas HTTP klientas)

Kadangi `vuci-app-openvpn-monitor-api` naudoja ta pati principa kaip `vuci-examples`, endpoint'ai atrodo taip:

- `GET /api/openvpn_mon_f/config` - grazina visu OpenVPN serveriu sarasa (patikrinta - `service_group` siai vuci versijai ConfigService tipo moduliams turi buti literaliai `config`, ne laisvai pasirenkamas vardas). Kiekvienam irasui prie standartiniu UCI lauku bus prideti `is_running`, `client_count` ir `connected_users`.
- `PUT /api/openvpn_mon_f/config/<sid>` su body `{"data":[{"id":"<sid>","disconnect_client":"vartotojo_vardas"}]}` - atjungia nurodyta vartotoja nuo konkretaus serverio (sid - tai konkrecio OpenVPN serverio UCI sekcijos id). Zr. zemiau esanti skyriu apie tikra testavima - PUT struktūra (masyvas su `id` viduje) nera akivaizdi is pirmo zvilgsnio.

Autorizacija/ACL sutvarkyta per `usr/share/rpcd/acl.d/openvpn_monitor.json` - jis leidzia skaityti ir rasyti `/openvpn_mon_f/*` bei `/openvpn_mon_c/*` keliams.

## patikrinta ir veikia (2026-08-03, RUTX10, RUTX_R_00.07.23.7)

1. Testinis OpenVPN serveris (su management interfeisu, per persurinkta `openvpn-openssl`) paleistas per procd, du tikri OpenVPN klientai prisijunge (skirtingi CN: `client1`, `client2`).
2. `ubus list | grep openvpn` rodo `openvpn.test_server`.
3. `ubus call openvpn.test_server get_users` grazina abu klientus su teisingais vardais, IP, baitais, laiku.
4. `ubus call openvpn.test_server disconnect_user '{"username":"client1"}'` realiai atjungia kliento sesija (patvirtinta - klientas is naujo prisijunge su nauju "connected_since" laiku).
5. `GET /api/openvpn_mon_f/config` (per HTTPS, su `Authorization: Bearer <token>`) grazina ta pati informacija per REST API.
6. `PUT /api/openvpn_mon_f/config/test_server` su `{"data":[{"id":"test_server","disconnect_client":"client2"}]}` realiai atjungia nurodyta vartotoja - patvirtinta, kad `client_count` sumazejo ir `client2` dingo is `connected_users` sarasso.
7. Procd `respawn` patikrintas - nuzudzius demono procesa rankiniu budu, jis automatiskai atsistate per kelias sekundes su nauju PID, ubus objektas atsirado is naujo be papildomu veiksmu.# OpenVPN-monitoring-task
