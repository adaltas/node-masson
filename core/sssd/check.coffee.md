
    export default header: 'SSSD Check', handler: ({options}) ->

## Runing Sevrice

Ensure the "sshd" service is up and running.

      @service.assert
        header: 'Service'
        name: 'sssd'
        installed: true
        started: true

## Check NSS

Check if NSS is correctly configured by executing the command `getent passwd
$user`. The command is only executed if a test user is defined by the
"sssd.test_user" property.

      @call
        header: 'NSS'
        if: -> options.test_user
        handler: ->
          {test_user} = ctx.config.sssd
          @system.execute
            cmd: "getent passwd #{test_user}"

## Check PAM

Check if PAM is correctly configured by executing the command
`sh -l $user -c 'whoami'`. This is only executed if a test
user is defined by the "sssd.test_user" property.

      @call
        header: 'PAM'
        if: -> options.test_user
        handler: ->
          {test_user} = ctx.config.sssd
          @system.execute
            cmd: "su -l #{test_user} -c 'whoami'"
