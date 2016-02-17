
# Kerberos Server Status

Check if the kadmin and krb5kdc daemons are running.

    module.exports = header: 'Kerberos Server Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status
        header: 'kadmin'
        name: 'kadmin'
      @service_status
        header:'krb5kdc'
        name:'krb5kdc'
