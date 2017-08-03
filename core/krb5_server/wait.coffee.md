
# Krb5 Server Wait

Wait for all the Kerberos servers deployed by Masson.

## Options

* `wait_kdc` ([[obj]])   
  Array or multi-dimentianal array containing objects with the host and port
  information to the KDC.

## Source Code

    module.exports = header: 'Kerberos Server Wait', label_true: 'READY', handler: (options) ->
      console.log options.wait_kdc
      @connection.wait
        header: 'Kadmin'
        servers: array.flatten options.wait_kdc

## Dependencies

    array = require 'nikita/lib/misc/array'
