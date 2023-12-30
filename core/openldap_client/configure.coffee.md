
# OpenLDAP Client Configure

```

```

    export default (service) ->
      options = service.options

## Configuration

      options.config ?= {}
      options.config['BASE'] ?= service.deps.openldap_server[0].options.suffix
      options.config['URI'] ?= service.deps.openldap_server.map( (srv) -> srv.options.uri ).join ' '
      options.config['TLS_CACERTDIR'] ?= '/etc/openldap/cacerts'
      options.config['TLS_REQCERT'] ?= 'demand' # Allow self-signed certificates, use "demand" otherwise
      options.config['TIMELIMIT'] ?= '15'
      options.config['TIMEOUT'] ?= '20'

## SSL/TLS

      options.certificates ?= []
      options.certificates = for cert in options.certificates
        cert = source: cert if typeof cert is 'string'
        cert.local ?= false
        cert

## Check

      options.check ?= {}
      options.check.suffix ?= service.deps.openldap_server[0].options.suffix
      options.check.root_dn ?= service.deps.openldap_server[0].options.root_dn
      options.check.root_password ?= service.deps.openldap_server[0].options.root_password

## Wait

      options.wait = {}
      options.wait.tcp = for uri in options.config['URI'].split ' '
        uri = url.parse uri
        throw Error "Invalid propotol: #{JSON.stringify uri.protocol}" unless uri.protocol in ['ldap:', 'ldaps:']
        uri.port ?= switch uri.protocol
          when 'ldap:' then 389
          when 'ldaps:' then 636
        host: uri.hostname
        port: uri.port

## Dependencies

    url = require 'url'
