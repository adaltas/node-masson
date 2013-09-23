
util = require 'util'
each = require 'each'
connect = require 'superexec/lib/connect'

config =
  host: 'hadoop1'
  username: 'root'
  password: null

connect config, (err, ssh) ->
  each([
    ((next) ->
      ssh.sftp (err, sftp) ->
        util.print '.'
        return next err if err
        sftp.stat '/etc/profile.d', (err, attr) ->
          sftp.end()
          next()
    )
    ((next) ->
      ssh.exec 'uptime', (err, stream) ->
        util.print '.'
        return next err if err
        stream.on 'data', (data) ->
          data
        stream.on 'exit', ->
        stream.on 'end', ->
        stream.on 'close', ->
          next()
    )
  ])
  .repeat(500)
  .on 'item', (callback, next) ->
    callback next
  .on 'end', ->
    ssh.end()

# c.exec('uptime', function(err, stream) {
#     if (err) throw err;
#     stream.on('data', function(data, extended) {
#       console.log((extended === 'stderr' ? 'STDERR: ' : 'STDOUT: ')
#                   + data);
#     });
#     stream.on('end', function() {
#       console.log('Stream :: EOF');
#     });
#     stream.on('close', function() {
#       console.log('Stream :: close');
#     });
#     stream.on('exit', function(code, signal) {
#       console.log('Stream :: exit :: code: ' + code + ', signal: ' + signal);
#       c.end();
#     });
#   });
