require! <[ path express dcs dcs/browser ]>

# configuration
require! '../config': {webserver-port, dcs-port}

# Create an in-memory authentication database
users = dcs.as-docs do
    'public':
        # hash algorithm is: sha512 =>
        #   `echo -n "public" | sha512sum`
        passwd-hash: "
            d32997e9747b65a3ecf65b82533a4c843c4e16dd30cf371e8c81ab60a341de00051
            da422d41ff29c55695f233a1e06fac8b79aeb0a4d91ae5d3d18c8e09b8c73"
        roles:
          \guest-permissions

permissions = dcs.as-docs do
    'guest-permissions':
        rw:
            \hello.**

db = new dcs.AuthDB users, permissions

# Create a webserver and a SocketIO bridge
app = express!
http = require \http .Server app
app.use "/", express.static path.resolve "../scada.js/build/main"
http.listen webserver-port, ->
    console.log "webserver is listening on *:#{webserver-port}"

new browser.DcsSocketIOServer http, {db}

# create a TCP DCS Service
new dcs.DcsTcpServer {port: dcs-port, db}
