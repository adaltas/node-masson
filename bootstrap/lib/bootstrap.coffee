
util = require 'util'
connect = require 'ssh2-connect'
exec = require 'ssh2-exec'

module.exports = (options, callback) ->
  {public_key, bootstrap} = @config.connection
  # ctx.log "SSH login to #{bootstrap.username}@#{bootstrap.host}:#{bootstrap.port}"
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
    # ctx.log "Command: #{cmd}"
    child = exec
      ssh: ssh
      cmd: cmd
    , (err) ->
      if err?.code is 2
        err = null
        rebooting = true
      callback err, rebooting
    # child.stdout.pipe ctx.log.out, end: false
    # child.stderr.pipe ctx.log.err, end: false
    child.stdout.on 'data', (data) ->
      options.log message: data, type: 'stdout'
    child.stdout.on 'end', (data) ->
      options.log message: null, type: 'stdout'
    child.stderr.on 'data', (data) ->
      options.log message: data, type: 'stderr'
    child.stderr.on 'end', (data) ->
      options.log message: null, type: 'stderr'
