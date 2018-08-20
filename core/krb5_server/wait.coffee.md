
# Krb5 Server Wait

Wait for all the Kerberos servers deployed by Masson.

## Options

* `wait_kdc` ([[obj]])   
  Array or multi-dimentianal array containing objects with the host and port
  information to the KDC.

## Source Code

    module.exports = header: 'Kerberos Server Wait', handler: ({options}) ->
      @connection.wait
        header: 'Kadmin'
        servers: options.kadmin

## Dependencies

    array = require 'nikita/lib/misc/array'
