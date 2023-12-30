
# SASLAuthd

saslauthd is a daemon process that handles plaintext authentication requests on 
behalf of the SASL library.

In LDAP authentication, the saslauthd process handles authentication requests 
on behalf of Couchbase Server while the LDAP protocol is used to connect to the 
LDAP server. 

    export default
      deps: {}
      configure:
        'masson/core/saslauthd/configure'
      commands:
        'check':
          'masson/core/saslauthd/check'
        'install':
          'masson/core/saslauthd/install'
        'start':
          'masson/core/saslauthd/start'
        'stop':
          'masson/core/saslauthd/stop'
