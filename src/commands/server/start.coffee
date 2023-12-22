
import server from 'masson/server'

export default ({params}, config) ->
  server.start
    directory: params.directory
    pidfile: params.pidfile
    port: params.port
  , (err, started) ->
    if err then switch err.code
      when 4
        console.error "Port #{params.port} already used"
        process.exit 4
      when 5
        console.error "Directory #{params.directory} does not exists"
        process.exit 5
      else
        console.log "Unkown Error, exit code is #{err.code}"
        process.exit 1
    if started
      console.log 'HTTP Server Started'
      process.exit 0
    else
      console.error 'HTTP Server Already Running'
      process.exit 3
