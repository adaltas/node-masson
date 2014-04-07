
util = require 'util'
connect = require 'ssh2-exec/lib/connect'
each = require 'each'

###

Note: we should use `echo password | sudo -S su -` as a more resilient approach.

###
module.exports = (ctx, callback) ->
  {username, password, cmd, public_key} = ctx.config.bootstrap
  public_key = public_key.join '\n'
  ctx.log "SSH login to #{username}@#{ctx.config.host}"
  connect ctx.config.bootstrap, (err, c) ->
    return callback err if err
    c.shell (err, stream) ->
      return callback err if err
      steps = []
      if username isnt 'root' then steps.push
        cmd: "#{cmd}\n"
        callback: (data, callback) ->
          if /mot de passe/.test(data.toLowerCase()) or /password/.test(data.toLowerCase())
            stream.write password
            stream.write '\n'
            callback()
          if /^\[root[\@]/.test data
            callback()
      steps.push
        cmd: "sed -i.back 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config\n"
        callback: (data, callback) ->
          callback() if /\[.+@.+ .+\]/.test data
      steps.push
        # There is a bug in CentOS 6 / SELinux that results in all client presented certificates to be ignored when SELinux is set to Enforcing.
        cmd: "sed -i.back 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config\n"
        callback: (data, callback) ->
          callback() if /\[.+@.+ .+\]/.test data
      steps.push
        cmd: "mkdir -p ~/.ssh; chmod 700 ~/.ssh\n"
        callback: (data, callback) ->
          callback() if /\[.+@.+ .+\]/.test data
      steps.push
        cmd: "echo '#{public_key}' >> ~/.ssh/authorized_keys\n"
        callback: (data, callback) ->
          callback() if /\[.+@.+ .+\]/.test data
      steps.push
        cmd: 'reboot\n'
        callback: (data, callback) ->
          callback() if /going down/.test data # or /reboot/.test data
      # Callback spaghetti
      current_callback = current_next = null
      stream.on 'data', (data) ->
        return unless current_callback
        ctx.log data.toString().split('\n').map((line) -> "<< #{line}").join('\n')
        current_callback data.toString(), ->
          current_next()
      process.stdin.resume()
      each(steps)
      .parallel(1)
      .on 'item', (step, next) ->
        current_callback = step.callback
        current_next = next
        ctx.log ">> #{step.cmd}"
        stream.write step.cmd
      .on 'both', (err) ->
        process.stdin.pause()
        setTimeout ->
          c.end()
        , 3000
    c.on 'error', (err) ->
      callback err
    c.on 'end', ->
      callback err



