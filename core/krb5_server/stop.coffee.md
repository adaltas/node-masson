
# Kerberos Server Stop

Stop the kadmin and krb5kdc daemons.

    export default header: 'Kerberos Server Stop', handler: ->
      @service.stop
        name: 'kadmin'
        name: 'kadmin'
      @service.stop
        header: 'krb5kdc'
        name: 'krb5kdc'
