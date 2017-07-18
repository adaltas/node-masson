
# Kerberos Server Stop

Stop the kadmin and krb5kdc daemons.

    module.exports = header: 'Kerberos Server Stop', label_true: 'STOPPED', handler: ->
      @service.stop
        name: 'kadmin'
        name: 'kadmin'
      @service.stop
        header: 'krb5kdc'
        name: 'krb5kdc'
