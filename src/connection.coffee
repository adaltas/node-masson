
fs = require 'fs'
Connection = require 'ssh2'
{merge} = require 'mecano/lib/misc'

###
Return an ssh connection
###
module.exports = (options) ->
  
  c = new Connection()
  c.connect merge {}, options,
    username: 'root'
    password: 'big123'
    port: 22
  c
