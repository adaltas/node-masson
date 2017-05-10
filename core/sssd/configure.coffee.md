
# SSSD Configure

## Configure

Option includes:

*   `sssd.certificates` (array)
    List of certificates to be uploaded to the server.
*   `sssd.merge`
    Merge the configuration with the one already present on the server, default
    to false.
*   `sssd.config`
*   `sssd.certificates`
*   `sssd.services` (array|string)
    List of services to install, default to `['sssd', 'sssd-client', 'pam_krb5', 'pam_ldap']`
*   `sssd.test_user`

Example:

```json
{
  "sssd": {
    "test_user": "test"
    "config":
      "domain/my_domain":
        "cache_credentials": "True"
        "ldap_search_base": "ou=users,dc=adaltas,dc=com"
        "ldap_group_search_base": "ou=groups,dc=adaltas,dc=com"
        "id_provider": "ldap"
        "auth_provider": "ldap"
        "chpass_provider": "ldap"
        "ldap_uri": "ldaps://master3.hadoop:636"
        "ldap_tls_cacertdir": "/etc/openldap/cacerts"
        "ldap_default_bind_dn": "cn=Manager,dc=adaltas,dc=com"
        "ldap_default_authtok": "test"
        "ldap_id_use_start_tls": "False"
      "sssd":
        "config_file_version": "2"
        "reconnection_retries": "3"
        "sbus_timeout": "30"
        "services": "nss, pam"
        "domains": "my_domain"
      "nss":
        "filter_groups": "root"
        "filter_users": "root"
        "reconnection_retries": "3"
        "entry_cache_timeout": "300"
        "entry_cache_nowait_percentage": "75"
      "pam":
        "reconnection_retries": "3"
        "offline_credentials_expiration": "2"
        "offline_failed_login_attempts": "3"
        "offline_failed_login_delay": "5"
    "certificates": [
      "#{__dirname}/certs-master3/master3.hadoop.ca.cer"
    ]
  }
}
```

    module.exports = ->
      sssd = @config.sssd ?= {}
      sssd.certificates ?= []
      sssd.merge ?= false
      
## Identities

      # Group
      sssd.group = name: sssd.group if typeof sssd.group is 'string'
      sssd.group ?= {}
      sssd.group.name ?= 'sssd'
      sssd.group.system ?= true
      # User
      sssd.user = name: sssd.user if typeof sssd.user is 'string'
      sssd.user ?= {}
      sssd.user.name ?= 'sssd'
      sssd.user.system ?= true
      sssd.user.gid = 'sssd'
      sssd.user.shell = false
      sssd.user.comment ?= 'SSSD User'
      sssd.user.home = '/'

## Configuration

      sssd.config = merge
        'sssd':
          'config_file_version' : '2'
          'reconnection_retries' : '3'
          'sbus_timeout' : '30'
          'services' : 'nss, pam'#Note on redhat 7, sudo must be added to become root using sssd
          'debug_level': '1'
        'nss':
          'filter_groups' : 'root'
          'filter_users' : 'root'
          'reconnection_retries' : '3'
          'entry_cache_timeout' : '300'
          'entry_cache_nowait_percentage' : '75'
          'debug_level': '1'
        'pam':
          'reconnection_retries' : '3'
          'offline_credentials_expiration' : '2'
          'offline_failed_login_attempts' : '3'
          'offline_failed_login_delay' : '5'
          'debug_level': '1'
      , sssd.config or {}
      sssd.test_user ?= null

The System Security Services Daemon (SSSD) provides access to different
identity and authentication providers.
      
      

## Clean "sssd" Cache

If the command `sss_cache -E` fail, the cache may be manually removed with:

```
cp -rp /var/lib/sss/db /var/lib/sss/db.bck
rm -rf /var/lib/sss/db/*
service sssd restart
```

## Dependencies

    {merge} = require 'nikita/lib/misc'
