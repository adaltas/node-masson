
# Krb5 Server Wait

Wait for all the Kerberos servers deployed by Masson.

## Options

* `wait_kdc` ([[obj]])   
  Array or multi-dimentianal array containing objects with the host and port
  information to the KDC.

## Source Code

    export default header: 'Kerberos Server Wait', handler: ({options}) ->
      @connection.wait
        header: 'Kadmin'
        servers: options.kadmin

## Dependencies

    array = require '@nikitajs/core/lib/misc/array'
