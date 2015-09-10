
# Kerberos Server Stop

    exports = module.exports = []
    exports.push 'masson/bootstrap'

    exports.push name: 'Kerberos Server # Stop kadmin', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'kadmin'
        action: 'stop'

    exports.push name: 'Kerberos Server # Stop krb5kdc', label_true: 'STOPPED', handler: ->
      @service
        srv_name: 'krb5kdc'
        action: 'stop'
