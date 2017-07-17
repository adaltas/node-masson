
{exec} = require 'child_process'
server = require 'http-server'
params = require '../params'

module.exports = ->
  params = params.parse()
  module.exports[params.action]()
      
module.exports.start = ->
  bin = require.resolve 'http-server/bin/http-server'
  exec """
  set -e
  if [ -f conf/server.pid ] ; then
    pid=`cat conf/server.pid`
    kill -0 $pid && exit 1
    rm -f conf/server.pid
  fi
  #{bin} conf/public -p 5680 -d -i >/dev/null 2>&1 &
  echo $! > conf/server.pid
  """, (err) ->
    if err
      console.error 'HTTP Server Not Started'
      process.exit 1
    console.log 'HTTP Server Started'
    process.exit 0
      
module.exports.stop = ->
  exec """
  set -e
  [ ! -f conf/server.pid ] && exit 2
  pid=`cat conf/server.pid`
  if ! kill -0 $pid ; then
    rm -f conf/server.pid
    exit 0
  fi
  kill $pid
  rm -f conf/server.pid
  """, (err, stdout, stderr) ->
    if err?.code is 2
      console.error 'HTTP Server Already Stopped'
      process.exit 1
    else if err
      console.error 'HTTP Server Kill Failed'
      process.exit 1
    console.log 'HTTP Server Stopped'
    process.exit 0
    
module.exports.status = ->
  exec """
  set -e
  [ ! -f conf/server.pid ] && exit 1
  pid=`cat conf/server.pid`
  ( ! kill -0 $pid ) && exit 1
  exit 0
  """, (err) ->
    if err
      console.error "HTTP Server Stopped"
      process.exit 1
    else
      console.error "HTTP Server Started"
      process.exit 0
  
