
# Kerberos Server Start

Start the kadmin and krb5kdc daemons.

    export default header: 'Kerberos Server Start', handler: ->
      @service.start
        header: 'kadmin'
        name: 'kadmin'
      @service.start
        header: 'krb5kdc'
        name: 'krb5kdc'
