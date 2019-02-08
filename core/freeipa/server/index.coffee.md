
# FreeIPA

Integrated security information management solution combining Linux (Fedora), 389 Directory Server
, MIT Kerberos, NTP, DNS, Dogtag certificate system, SSSD and others.
Built on top of well known Open Source components and standard protocols
Strong focus on ease of management and automation of installation and configuration tasks.
Full multi master replication for higher redundancy and scalability
Extensible management interfaces (CLI, Web UI, XMLRPC and JSONRPC API) and Python SDK

This modules follows the [quick start guide](https://www.freeipa.org/page/Quick_Start_Guide) 
Each module belonging to FreeIPA (LDAP, MIT Kerberos, DNS) is separated in its own install module.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        system: module: 'masson/core/system', local: true #rngd entropy
        ssl: module: 'masson/core/ssl', local: true
        network: module: 'masson/core/network', local: true
        openldap_server:  module: 'masson/core/openldap_server'
        krb5_server:  module: 'masson/core/krb5_server'
        
      configure:
        'masson/core/freeipa/server/configure'
      commands:
        'check':
          'masson/core/freeipa/server/check'
        'install': [
          'masson/core/freeipa/server/install'
          # 'masson/core/freeipa/server/start'
          # 'masson/core/freeipa/server/check'
        ]
        'start':
          'masson/core/freeipa/server/start'
        'status':
          'masson/core/freeipa/server/status'
        'stop':
          'masson/core/freeipa/server/stop'
