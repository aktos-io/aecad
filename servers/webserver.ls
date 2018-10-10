require! \path
require! \express
require! 'dcs/services/dcs-proxy': {AuthDB, DcsSocketIOServer, DcsTcpServer}

# configuration
require! '../config': {webserver-port, dcs-port}

# Create a webserver
app = express!
http = require \http .Server app
app.use "/", express.static path.resolve "../scada.js/build/main"
http.listen webserver-port, "0.0.0.0", ->
    console.log "webserver is listening on *:#{webserver-port}"

# Create auth db
db = new AuthDB (require './users' .users)
# use ..update(users) to add more users in the runtime

# Create a SocketIO bridge
new DcsSocketIOServer http, {db}

# Create a TCP DCS Service
new DcsTcpServer {port: dcs-port, db}
