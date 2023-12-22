
import server from 'masson/server'

export default ({params}, config)->
  server.stop
    pidfile: params.pidfile
  , (err, stopped) ->
    if err
      console.error 'HTTP Server Kill Failed'
      process.exit 1
    if stopped
      console.log 'HTTP Server Stopped'
      process.exit 0
    else
      console.error 'HTTP Server Already Stopped'
      process.exit 3
