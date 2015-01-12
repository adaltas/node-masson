---
title: Kerberos with OpenLDAP Back-End
module: masson/core/krb5_server
layout: module
---

## Kerberos Server

Kerberos is a network authentication protocol. It is designed to provide strong
authentication for client/server applications by using secret-key cryptography.
The module install the free implementation of this protocol available from the
Massachusetts Institute of Technology.

The article [SSH Kerberos Authentication Using GSSAPI and SSPI][gss_sspi]
provides a good description on how Kerberos is negotiated by GSSAPI and SSPI.

    module.exports = []
    module.exports.push require('../krb5_client').configure
    module.exports.push require('../iptables').configure

## Configuration

*   `krb5_server.{realm}.ldap_manager_dn` (string)   
    The LDAP user with read and write access to the realm dn
    defined by the `ldap_realms_dn` property. Default to the 
    `openldap_server_krb5.manager_dn` property if you have one OpenLDAP server with 
    kerberos support declared inside the cluster by the 
    "masson/core/openldap\_server\_krb5" module, otherwise required.      
*   `krb5_server.{realm}.ldap_manager_password` (string)   
    The password of the LDAP user with read and write access to the realm dn
    defined by the `ldap_realms_dn` property. Default to the 
    `openldap_server_krb5.manager_password` property if you have one OpenLDAP server with 
    kerberos support declared inside the cluster by the 
    "masson/core/openldap\_server\_krb5" module, otherwise required.      
*   `krb5_server.{realm}.ldap_realms_dn` (string)   
    The location where to store the realms inside the LDAP tree. Default to the 
    `openldap_server_krb5.realms_dn` property if you have one OpenLDAP server with 
    kerberos support declared inside the cluster by the 
    "masson/core/openldap\_server\_krb5" module, otherwise required.   

Example:

```json
{
  "krb5": {
    "etc_krb5_conf": {
      "libdefaults": {
        "default_realm": "HADOOP.RYBA"
      },
      "realms": {
        "HADOOP.RYBA": {
          "default_domain": "ryba",
          "kadmin_principal": "wdavidw/admin@HADOOP.RYBA",
          "kadmin_password": "test",
          "principals": [{
            "principal": "wdavidw@HADOOP.RYBA",
            "password": "test"
          },{
            "principal": "krbtgt/HADOOP.RYBA@USERS.RYBA",
            "password": "test"
          }]
        }
      }
      "domain_realm": {
        ".ryba": "HADOOP.RYBA",
        "ryba": "HADOOP.RYBA"
      },
    },
    "kdc_conf": {
      "dbmodules": {
        "openldap_master3": {
          "kdc_master_key": "test"
        }
      }
    }
  }
}
```

    module.exports.safe_etc_krb5_conf = (etc_krb5_conf) ->
      etc_krb5_conf = misc.merge {}, etc_krb5_conf
      for realm, config of etc_krb5_conf.realms
        delete config.kadmin_principal
        delete config.kadmin_password
        delete config.principals
      for name, config of etc_krb5_conf.dbmodules
        delete config.kdc_master_key
        delete config.manager_dn
        delete config.manager_password
        delete config.ldap_kdc_password
        delete config.ldap_kadmind_password
      etc_krb5_conf

    module.exports.configure = (ctx) ->
      {etc_krb5_conf} = ctx.config.krb5
      openldap_hosts = ctx.hosts_with_module 'masson/core/openldap_server/install_krb5'
      throw new Error "Expect at least one server with action \"masson/core/openldap_server/install_krb5\"" if openldap_hosts.length is 0
      # Prepare configuration for "kdc.conf"
      kdc_conf = ctx.config.krb5.kdc_conf ?= {}
      # Generate dynamic "krb5.dbmodules" object
      for host in openldap_hosts
        ctx_krb5 = ctx.hosts[host]
        require('../openldap_server/install_krb5').configure ctx_krb5
        {kerberos_dn, kdc_user, krbadmin_user, manager_dn, manager_password} = ctx_krb5.config.openldap_server_krb5
        name = "openldap_#{host.split('.')[0]}"
        scheme = if ctx.hosts[host].has_module 'masson/core/openldap_server/install_tls' then "ldap://" else "ldaps://"
        ldap_server =  "#{scheme}#{host}"
        kdc_conf.dbmodules[name] = misc.merge
          'db_library': 'kldap'
          'ldap_kerberos_container_dn': kerberos_dn
          'ldap_kdc_dn': kdc_user.dn
          'ldap_kdc_password': kdc_user.userPassword
           # this object needs to have read rights on
           # the realm container, principal container and realm sub-trees
          'ldap_kadmind_dn': krbadmin_user.dn
          'ldap_kadmind_password': krbadmin_user.userPassword
           # this object needs to have read and write rights on
           # the realm container, principal container and realm sub-trees
          'ldap_service_password_file': "/etc/krb5.d/#{name}.stash.keyfile"
          # 'ldap_servers': 'ldapi:///'
          'ldap_servers': ldap_server
          'ldap_conns_per_server': 5
          'manager_dn': manager_dn
          'manager_password': manager_password
        , kdc_conf.dbmodules[name]
        ldapservers = kdc_conf.dbmodules[name].ldap_servers
        kdc_conf.dbmodules[name].ldap_servers = ldapservers.join ' ' if Array.isArray ldapservers
      # Set default
      misc.merge kdc_conf,
        'kdcdefaults':
          'kdc_ports': '88'
          'kdc_tcp_ports': '88'
        'realms': {}
        'logging':
            'kdc': 'FILE:/var/log/kdc.log'
      , kdc_conf
      # Multiple kerberos servers accross the cluster are defined in server
      # specific configuration
      realms = ctx.config.servers[ctx.config.host].krb5?.etc_krb5_conf?.realms
      realms = etc_krb5_conf.realms if not realms or realms.length is 0
      for realm, i of realms
        kdc_conf.realms[realm] ?= {}
      # Set default values each realm
      for realm, config of kdc_conf.realms
        kdc_conf.realms[realm] = misc.merge
          # 'kadmind_port': 749
          # 'kpasswd_port': 464 # http://www.opensource.apple.com/source/Kerberos/Kerberos-47/KerberosFramework/Kerberos5/Documentation/kadmin/kpasswd.protocol
          'max_life': '10h 0m 0s'
          'max_renewable_life': '7d 0h 0m 0s'
          #'master_key_type': 'aes256-cts'
          'master_key_type': 'aes256-cts-hmac-sha1-96'
          'default_principal_flags': '+preauth'
          'acl_file': '/var/kerberos/krb5kdc/kadm5.acl'
          'dict_file': '/usr/share/dict/words'
          'admin_keytab': '/var/kerberos/krb5kdc/kadm5.keytab'
          #'supported_enctypes': 'aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal'
          'supported_enctypes': 'aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal des3-hmac-sha1:normal arcfour-hmac-md5:normal'
        , config
      for realm, config of kdc_conf.realms
        # Check if realm point to a database_module
        if config.database_module
          # Make sure this db module is registered
          dbmodules = Object.keys(kdc_conf.dbmodules).join ','
          valid = kdc_conf.dbmodules[config.database_module]?
          throw new Error "Property database_module \"#{config.database_module}\" not in list: \"#{dbmodules}\"" unless valid
        # Set a database module if we manage the realm locally
        else if etc_krb5_conf.realms[realm].admin_server is ctx.config.host
          # Valid if
          # *   only one OpenLDAP server accross the cluster or
          # *   an OpenLDAP server in this host
          openldap_index = openldap_hosts.indexOf ctx.config.host
          openldap_host = if openldap_hosts.length is 1 then openldap_hosts[0] else if openldap_index isnt -1 then openldap_hosts[openldap_index]
          throw new Error "Could not find a suitable OpenLDAP server" unless openldap_host
          config.database_module = "openldap_#{openldap_host.split('.')[0]}"
        config.principals ?= []
      # Now that we have db_modules and realms, filter and validate the used db_modules
      database_modules = for realm, config of kdc_conf.realms
        config.database_module
      for name, config of kdc_conf.dbmodules
        # Filter
        if database_modules.indexOf(name) is -1
          delete kdc_conf.dbmodules[name]
          continue
        # Validate
        throw new Error "Kerberos property `krb5.dbmodules.#{name}.kdc_master_key` is required" unless config.kdc_master_key
        throw new Error "Kerberos property `krb5.dbmodules.#{name}.ldap_kerberos_container_dn` is required" unless config.ldap_kerberos_container_dn
        throw new Error "Kerberos property `krb5.dbmodules.#{name}.ldap_kdc_dn` is required" unless config.ldap_kdc_dn
        throw new Error "Kerberos property `krb5.dbmodules.#{name}.ldap_kadmind_dn` is required" unless config.ldap_kadmind_dn

    # module.exports.push commands: 'backup', modules: 'masson/core/krb5_server_backup'

    # module.exports.push commands: 'check', modules: 'masson/core/krb5_server_check'

    module.exports.push commands: 'install', modules: [
      'masson/core/krb5_server/install'
      'masson/core/krb5_server/start'
    ]

    # module.exports.push commands: 'reload', modules: 'masson/core/krb5_server/install'

    module.exports.push commands: 'start', modules: 'masson/core/krb5_server/start'

    module.exports.push commands: 'status', modules: 'masson/core/krb5_server/status'

    module.exports.push commands: 'stop', modules: 'masson/core/krb5_server/stop'

## Module Dependencies

    misc = require 'mecano/lib/misc'

[gss_sspi]: http://www.drdobbs.com/ssh-kerberos-authentication-using-gssapi/184402071




