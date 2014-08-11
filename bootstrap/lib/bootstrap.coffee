
util = require 'util'
connect = require 'ssh2-connect'
each = require 'each'

module.exports = (ctx, callback) ->
  {public_key, bootstrap} = ctx.config.connection
  return callback Error "Invalid public_key: #{JSON.stringify public_key}" unless Array.isArray public_key
  public_key = public_key.join '\n'
  ctx.log "SSH login to #{bootstrap.username}@#{ctx.config.host}"
  connect bootstrap, (err, conn) ->
    return callback err if err
    conn.shell (err, stream) ->
      return callback err if err
      stream.pipe ctx.log.out, end: false
      stream.stderr.pipe ctx.log.err, end: false
      exit = 0
      stream.stderr.on 'end', ->
        console.log 'EEEEENNNNDD stderr'
        conn.end() if ++exit is 3
      stream.on 'exit', (code, signal) ->
        console.log 'EEXXXXXIITT', code
        conn.end() if ++exit is 3
      stream.on 'end', ->
        console.log 'EEEEENNNNDD stdout'
        conn.end() if ++exit is 3
      steps = []
      if bootstrap.username isnt 'root' then steps.push
        cmd: "#{bootstrap.cmd}\n"
        callback: (data, next) ->
          if /^\[root[\@]/.test data
            next()
          else if /mot de passe/.test(data.toLowerCase()) or /password/.test(data.toLowerCase())
            console.log 'write password'
            stream.write "#{bootstrap.password}\n"
      steps.push
        cmd: "sed -i.back 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config\n"
        callback: (data, next) ->
          next() if /\[.+@.+ .+\]/.test data
      steps.push
        cmd: "mkdir -p ~/.ssh; chmod 700 ~/.ssh\n"
        callback: (data, next) ->
          next() if /\[.+@.+ .+\]/.test data
      steps.push
        cmd: "echo '#{public_key}' >> ~/.ssh/authorized_keys\n"
        callback: (data, next) ->
          next() if /\[.+@.+ .+\]/.test data
      steps.push
        # There is a bug in CentOS 6 / SELinux that results in all client presented certificates to be ignored when SELinux is set to Enforcing.
        cmd: "if grep ^SELINUX=enforcing /etc/selinux/config; then sed -i.back 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config; reboot; fi;\n" # reboot;
        callback: (data, next) ->
          next() if /\[.+@.+ .+\]/.test data
      root_exit = if bootstrap.username isnt 'root' then 'exit\n' else ''
      steps.push
        cmd: "#{root_exit}exit\n"
        callback: (data, next) ->
          next() if /\[.+@.+ .+\]/.test data
      each(steps)
      .parallel(1)
      .on 'item', (step, i, next) ->
        ctx.log "Bootstrap write: #{step.cmd}"
        data = ''
        stream.on 'data', (buf) ->
          step.callback buf.toString(), ->
            stream.removeAllListeners 'data'
            next()
        if i < steps.length - 1
          stream.write step.cmd
        else
          stream.end step.cmd
      .on 'both', (err) ->
        console.log 'EXIT'
    conn.on 'error', (err) ->
      callback if err.code is 'ECONNREFUSED' then null else err
    conn.on 'end', ->
      callback()



