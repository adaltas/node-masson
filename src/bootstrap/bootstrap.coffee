
util = require 'util'
connect = require 'superexec/lib/connect'
each = require 'each'

###
Exemple calling prepare with options

    prepare
      host: 'noeyy0lm.adam.adroot.edf.fr'
      port: 22
      username: 'admsrv'
      password: 'password'
      public_key: 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuYziVgwFAXvExxIj5HgAywFeSfu9zxoLc5bCdeJhS/gh4EtpMN0McHd21M4btuopMAL/sctT4+SiBqwOIERw0rGWrat4WE2qBReEc+6hvdoiUx+7WglDCYePbV91N+x421UYzHhNPUg62jXIfg+o5zG/tdEDbpBAq2EX3vRsncenlhB+p/LsSkY+2+tBJLW172BN1ncKjImFglMwW+7OxGP2U9LoMMFyUs1zS65p8WgHHi/+6ZNsP0wIhKPPl8BiFJ6dLiNjlRuXLX9fGcQDJGrlYbad5Thb5wpQe1EZCF9qBloUkdj7aTIu+dainTP/I87Eo2Y47KsSydvopjqceQ== david@adaltas.com'

###
module.exports = (ctx, callback) ->
  {username, password, cmd, public_key} = ctx.config.bootstrap
  public_key = public_key.join '\n'
  connect ctx.config.bootstrap, (err, c) ->
    return callback err if err
    c.shell (err, stream) ->
      return callback err if err
      steps = []
      if username isnt 'root' then steps.push
        cmd: "#{cmd}\n"
        callback: (data, callback) ->
          if /Mot de passe/.test(data) or /Password/.test(data)
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
      # steps.push
      #   cmd: 'yum -y update\n'
      #   callback: (data, callback) ->
      #     callback() if /\[.+@.+ .+\]/.test data
      steps.push
        cmd: 'reboot\n'
        callback: (data, callback) ->
          callback() if /going down/.test data # or /reboot/.test data
      # Callback spaghetti
      current_callback = current_next = null
      stream.on 'data', (data) ->
        return unless current_callback
        current_callback data.toString(), ->
          current_next()
      process.stdin.resume()
      each(steps)
      .parallel(1)
      .on 'item', (step, next) ->
        current_callback = step.callback
        current_next = next
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



