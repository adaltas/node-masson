
util = require 'util'
connect = require 'ssh2-connect'
exec = require 'ssh2-exec'

module.exports = (ctx, callback) ->
  {public_key, bootstrap} = ctx.config.connection
  # return callback Error "Invalid public_key: #{JSON.stringify public_key}" unless Array.isArray public_key
  # public_key = public_key.join '\n'
  ctx.log "SSH login to #{bootstrap.username}@#{bootstrap.host}:#{bootstrap.port}"
  connect bootstrap, (err, ssh) ->
    cmd = """
      sed -i.back 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config;
      mkdir -p /root/.ssh; chmod 700 /root/.ssh;
      echo '#{public_key}' >> /root/.ssh/authorized_keys;
      if [ -f /etc/selinux/config ] && grep ^SELINUX=enforcing /etc/selinux/config;
      then
        sed -i.back 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config;
        reboot;
        exit 2;
      fi;
      """
    if bootstrap.username isnt 'root'
      cmd = "echo -e \"#{bootstrap.password}\\n\" | sudo -S -- sh -c \"#{cmd.replace /\n/g, ' '}\""
    ctx.log "Command: #{cmd}"
    # cmd = (cmd) ->
    #   prefix = suffix = ''
    #   if bootstrap.username isnt 'root'
    #     prefix = "echo -e \"#{bootstrap.password}\\n\" | sudo -S -- sh <<EOF\n" 
    #     suffix = "\nEOF\n"
    #   cmd = "#{prefix} #{cmd} #{suffix}"
    #   ctx.log "Command: #{cmd}"
    #   cmd
    child = exec
      ssh: ssh
      # cmd: cmd """
      # sed -i.back 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
      # mkdir -p /root/.ssh; chmod 700 /root/.ssh
      # echo '#{public_key}' >> /root/.ssh/authorized_keys
      # if [ -f /etc/selinux/config ] && grep ^SELINUX=enforcing /etc/selinux/config
      # then
      #   sed -i.back 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config;
      #   reboot
      #   exit 2
      # fi
      # """
      cmd: cmd
    , (err) ->
      if err?.code is 2
        err = null
        rebooting = true
      callback err, rebooting
    child.stdout.pipe ctx.log.out, end: false
    child.stderr.pipe ctx.log.err, end: false

  # connect bootstrap, (err, conn) ->
  #   return callback err if err
  #   conn.shell (err, stream) ->
  #     return callback err if err
  #     stream.pipe ctx.log.out, end: false
  #     stream.stderr.pipe ctx.log.err, end: false
  #     exit = 0
  #     stream.stderr.on 'end', ->
  #       conn.end() if ++exit is 3
  #     stream.on 'exit', (code, signal) ->
  #       conn.end() if ++exit is 3
  #     stream.on 'end', ->
  #       conn.end() if ++exit is 3
  #     steps = []
  #     if bootstrap.username isnt 'root' then steps.push
  #       cmd: "#{bootstrap.cmd}\n"
  #       handler: (data, next) ->
  #         stream.write "#{bootstrap.password}\n"
  #         next()
  #         # console.log data
  #         # if /mot de passe/.test(data.toLowerCase()) or /password/.test(data.toLowerCase())
  #         #   stream.write "#{bootstrap.password}\n"
  #         # else
  #         #   next()
  #         # if /^\[root[\@]/.test data
  #         #   next()
  #         # else if /mot de passe/.test(data.toLowerCase()) or /password/.test(data.toLowerCase())
  #         #   stream.write "#{bootstrap.password}\n"
  #     steps.push
  #       cmd: "sed -i.back 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config\n"
  #       handler: (data, next) ->
  #         next()
  #         # next() if /\[.+@.+ .+\]/.test data
  #     steps.push
  #       cmd: "mkdir -p ~/.ssh; chmod 700 ~/.ssh\n"
  #       handler: (data, next) ->
  #         next()
  #         # next() if /\[.+@.+ .+\]/.test data
  #     steps.push
  #       cmd: "echo '#{public_key}' >> ~/.ssh/authorized_keys\n"
  #       handler: (data, next) ->
  #         next()
  #         # next() if /\[.+@.+ .+\]/.test data
  #     steps.push
  #       # There is a bug in CentOS 6 / SELinux that results in all client presented certificates to be ignored when SELinux is set to Enforcing.
  #       cmd: "if [ -f /etc/selinux/config ] && grep ^SELINUX=enforcing /etc/selinux/config; then sed -i.back 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config; reboot; fi;\n" # reboot;
  #       handler: (data, next) ->
  #         next()
  #         # next() if /\[.+@.+ .+\]/.test data
  #     root_exit = if bootstrap.username isnt 'root' then 'exit\n' else ''
  #     steps.push
  #       cmd: "#{root_exit}\n"
  #       handler: (data, next) ->
  #         next()
  #         # next() if /\[.+@.+ .+\]/.test data
  #     each(steps)
  #     .parallel(1)
  #     .on 'item', (step, i, next) ->
  #       ctx.log "Bootstrap write: #{step.cmd}"
  #       data = ''
  #       stream.on 'data', (buf) ->
  #         step.callback buf.toString(), ->
  #           stream.removeAllListeners 'data'
  #           next()
  #       if i < steps.length - 1
  #         stream.write step.cmd
  #       else
  #         stream.end step.cmd
  #     .on 'both', (err) ->
  #       # EXIT
  #   conn.on 'error', (err) ->
  #     callback if err.code is 'ECONNREFUSED' then null else err
  #   conn.on 'end', ->
  #     callback()



