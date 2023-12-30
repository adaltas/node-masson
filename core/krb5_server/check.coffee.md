
# Kerberos Server Check

Check the health of the Bind server.

    export default header: 'Kerberos Server Check', handler: ({options}) ->

## Runing Sevrice

Ensure the services are up and running.

      @service.assert
        header: 'Package Installed'
        name: 'krb5-server'
        installed: true
      @service.assert
        header: 'Service krb5kdc'
        name: 'krb5kdc'
        started: true
      @service.assert
        header: 'Service kadmin'
        name: 'krb5kdc'
        started: true

## Connections

      @connection.assert
        header: 'Kadmin'
        servers: options.kadmin

## Local kadmin Client

      @system.execute
        header: 'Local kadmin'
        cmd: """
        export KRB5_KDC_PROFILE='/var/kerberos/krb5kdc/kdc.conf'
        kadmin.local -q 'listprincs' | grep krbtgt
        """
