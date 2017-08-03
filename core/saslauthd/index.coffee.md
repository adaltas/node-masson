
# SASLAuthd

saslauthd is a daemon process that handles plaintext authentication requests on 
behalf of the SASL library.

In LDAP authentication, the saslauthd process handles authentication requests 
on behalf of Couchbase Server while the LDAP protocol is used to connect to the 
LDAP server. 

    module.exports =
      use: {}
      configure:
        'masson/core/saslauthd/configure'
      commands:
        'check': ->
          options = @config.saslauthd
          @call 'masson/core/saslauthd/check', options
        'install': ->
          options = @config.saslauthd
          @call 'masson/core/saslauthd/install', options
        'start':
          'masson/core/saslauthd/start'
        'stop':
          'masson/core/saslauthd/stop'
