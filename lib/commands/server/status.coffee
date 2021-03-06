
server = require '../../server'

module.exports = ({params}, config) ->
  server.status
    pidfile: params.pidfile
  , (err, started) ->
    if started
      console.error "HTTP Server Started"
      process.exit 0
    else
    console.error "HTTP Server Stopped"
    process.exit 1
