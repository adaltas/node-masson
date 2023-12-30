
# Krb5 Client Wait

Wait for all the Kerberos servers referenced by the client configuration.

    export default header: 'Krb5 Client Wait', handler: ({options}) ->

## Wait Admin

Wait for the Admin Server to listen for TCP connection, by default on port 749.

      @connection.wait
        header: 'TCP Admin'
        if: options.kadmin_tcp.length
        quorum: 1
        servers: options.kadmin_tcp

## Wait Admin

Wait for the admin interface to be ready by issuing the command `listprincs`.
Option "retry" is set to "2" because we get a lot of "null exit code" errors
and we couldnt dig the exact nature of this error.

      @wait.execute (
        header: 'kadmin'
        retry: 10
        interval: 10000
        cmd: cmd
        stdin_log: true
        stdout_log: false
        stderr_log: false
      ) for cmd in options.kadmin_listprincs

## Module Dependencies

    misc = require '@nikitajs/core/lib/misc'
