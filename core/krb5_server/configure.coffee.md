
## Kerberos Server Configure

*   `krb5_server.{realm}.ldap_manager_dn` (string)   
    The LDAP user with read and write access to the realm dn
    defined by the `ldap_realms_dn` property. Default to the 
    `openldap_server.krb5.manager_dn` property if you have one OpenLDAP server with 
    kerberos support declared inside the cluster by the 
    "masson/core/openldap\_server\_krb5" module, otherwise required.      
*   `krb5_server.{realm}.ldap_manager_password` (string)   
    The password of the LDAP user with read and write access to the realm dn
    defined by the `ldap_realms_dn` property. Default to the 
    `openldap_server.krb5.manager_password` property if you have one OpenLDAP server with 
    kerberos support declared inside the cluster by the 
    "masson/core/openldap\_server\_krb5" module, otherwise required.      
*   `krb5_server.{realm}.ldap_realms_dn` (string)   
    The location where to store the realms inside the LDAP tree. Default to the 
    `openldap_server.krb5.realms_dn` property if you have one OpenLDAP server with 
    kerberos support declared inside the cluster by the 
    "masson/core/openldap\_server\_krb5" module, otherwise required.   

Example:

```json
{
  "admin": {
    "HADOOP.RYBA": {
      "default_domain": "ryba",
      "kadmin_principal": "wdavidw/admin@HADOOP.RYBA",
      "kadmin_password": "test",
      "kdc_master_key": "test",
      "database_module": "mydbmodule",
      "principals": [{
        "principal": "wdavidw@HADOOP.RYBA",
        "password": "test"
      },{
        "principal": "krbtgt/HADOOP.RYBA@USERS.RYBA",
        "password": "test"
      }]
    }
  }
}
```

    export default (service) ->
      options = service.options
      options.fqdn = service.node.fqdn

## Validation

      throw new Error "Expect at least one server with action \"masson/core/openldap_server\"" if not service.deps.openldap_server or service.deps.openldap_server.length is 0

## Configuration

      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      # Prepare configuration for "kdc.conf"
      options.root_dn ?= service.deps.openldap_server[0].options.root_dn
      options.root_password ?= service.deps.openldap_server[0].options.root_password

## HA

High availability for the KDC is based on a master-slave architecture. If not 
declared in the configuration, the first KDC found is considered the master. To 
declare the master server, set the property "config.{realm}.master" to "true" 
on the appropriate node.
The property `ha_deploy_master` describes which host is used to initialized the realm db.
ryba will first execute operation on this host and enable the slave replication aftwerwards.


      options.ha_deploy_master ?= {}
      for realm, config of options.admin
        config.ha = service.deps.krb5_server.length > 1
        if config.ha
          master_count = service.deps.krb5_server.filter( (srv) -> srv.options.admin?[realm]?.master ).length
          options.ha_deploy_master[realm] ?= service.deps.krb5_server.filter( (srv) -> srv.options.admin?[realm]?.master )[0]?.node.fqdn if master_count is 1
          throw Error 'Invalid configuration: more than one KDC server' if master_count > 1
          if master_count is 0
            mutate service.deps.krb5_server[0].options, admin: "#{realm}": master: true
            options.ha_deploy_master[realm] ?= service.deps.krb5_server[0].node.fqdn

## kdc.conf

The kdc.conf file supplements krb5.conf for programs which are typically only 
used on a KDC, such as the krb5kdc and kadmind daemons and the kdb5_util 
program. Relations documented here may also be specified in krb5.conf; for the 
KDC programs mentioned, krb5.conf and kdc.conf will be merged into a single 
configuration profile.

      # Default values
      options.kdc_conf ?= {}
      options.kdc_conf = merge
        'libdefaults': {}
        'kdcdefaults':
          'kdc_ports': '88'
          'kdc_tcp_ports': '88'
        'realms': {}
        'logging':
            'kdc': 'FILE:/var/log/kdc.log'
      , options.kdc_conf
      # throw Error 'Required option: kdc_conf.libdefaults.default_realm' unless options.kdc_conf.libdefaults.default_realm
      for realm, config of options.admin
        config.admin_server ?= service.node.fqdn
        config.realm ?= realm
        options.kdc_conf.realms[realm] ?= {}
        options.kdc_conf.libdefaults.default_realm ?= realm
      for realm, config of options.kdc_conf.realms
        admin = options.admin[realm]
        # DB module
        options.kdc_conf.dbmodules ?= {}
        options.kdc_conf.dbmodules[admin.database_module] = merge
          'db_library': 'kldap'
          'ldap_kerberos_container_dn': service.deps.openldap_server[0].options.krb5.kerberos_dn
          'ldap_kdc_dn': service.deps.openldap_server[0].options.krb5.kdc_user.dn
          'ldap_kdc_password': service.deps.openldap_server[0].options.krb5.kdc_user.userPassword
           # this object needs to have read rights on
           # the realm container, principal container and realm sub-trees
          'ldap_kadmind_dn': service.deps.openldap_server[0].options.krb5.krbadmin_user.dn
          'ldap_kadmind_password': service.deps.openldap_server[0].options.krb5.krbadmin_user.userPassword
           # this object needs to have read and write rights on
           # the realm container, principal container and realm sub-trees
          'ldap_service_password_file': "/etc/krb5.d/#{admin.database_module}.stash.keyfile"
          # 'ldap_servers': 'ldapi:///'
          'ldap_servers': service.deps.openldap_server.map((srv) -> srv.options.uri).join ' '
          'ldap_conns_per_server': 5
          'kdc_master_key': admin.kdc_master_key
        , options.kdc_conf.dbmodules[admin.database_module]
        # Default realm configuration
        config = options.kdc_conf.realms[realm] = merge
          'kadmind_port': 749
          # 'kpasswd_port': 464 # http://www.opensource.apple.com/source/Kerberos/Kerberos-47/KerberosFramework/Kerberos5/Documentation/kadmin/kpasswd.protocol
          'max_life': '10h 0m 0s'
          'max_renewable_life': '7d 0h 0m 0s'
          #'master_key_type': 'aes256-cts'
          'master_key_type': 'aes256-cts-hmac-sha1-96'
          'default_principal_flags': '+preauth, +renewable, +forwardable'
          'acl_file': '/var/kerberos/krb5kdc/kadm5.acl'
          'dict_file': '/usr/share/dict/words'
          'admin_keytab': '/var/kerberos/krb5kdc/kadm5.keytab'
          #'supported_enctypes': 'aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal'
          'supported_enctypes': 'aes256-cts-hmac-sha1-96:normal aes128-cts-hmac-sha1-96:normal des3-hmac-sha1:normal arcfour-hmac-md5:normal'
        , options.kdc_conf.realms[realm]
        # Check if realm point to a database_module
        if config.database_module
          # Make sure this db module is registered
          dbmodules = Object.keys(options.kdc_conf.dbmodules).join ','
          valid = options.kdc_conf.dbmodules[config.database_module]?
          throw new Error "Property database_module: \"#{config.database_module}\" not in list: \"#{}\"" unless valid
        else if Object.keys(options.kdc_conf.dbmodules).length is 1
          database_module = Object.keys(options.kdc_conf.dbmodules)[0]
          config.database_module = admin.database_module
        else
          throw Error "Cannot associate realm with a database_module"
        config.principals ?= []
      # Now that we have db_modules and realms, filter and validate the used db_modules
      database_modules = for realm, config of options.kdc_conf.realms
        config.database_module
      for name, config of options.kdc_conf.dbmodules
        # Filter
        if database_modules.indexOf(name) is -1
          delete options.kdc_conf.dbmodules[name]
          continue
        # Validate
        throw new Error "Kerberos property `dbmodules.#{name}.kdc_master_key` is required" unless config.kdc_master_key
        throw new Error "Kerberos property `dbmodules.#{name}.ldap_kerberos_container_dn` is required" unless config.ldap_kerberos_container_dn
        throw new Error "Kerberos property `dbmodules.#{name}.ldap_kdc_dn` is required" unless config.ldap_kdc_dn
        throw new Error "Kerberos property `dbmodules.#{name}.ldap_kadmind_dn` is required" unless config.ldap_kadmind_dn

## Wait
    
      options.wait_ldap_client = service.deps.openldap_client.options.wait
      options.wait = {}
      options.wait.kadmin = for realm, config of options.kdc_conf.realms
        host: service.node.fqdn
        port: config.kadmind_port

## Dependencies

    {merge, mutate} = require 'mixme'
