
# Kerberos Server Status

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Kadmin Status

    exports.push header: 'Kerberos Server # Status kadmin', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name: 'kadmin'

## KDC Status

    exports.push header: 'Kerberos Server # Status krb5kdc', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service_status name:'krb5kdc'
