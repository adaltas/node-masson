
export default ({options, node, deps}) ->
  options.fqdn ?= node.fqdn
  options.ip_address ?= node.ip
  # Deprecation
  throw Error 'Option dns_autoforward is deprecated, use dns_auto_forward' if options.dns_autoforward?
  # Indentites
  options.manage_users_groups ?= true
  # Group
  options.hsqldb ?= {}
  options.hsqldb.group = name: options.hsqldb.group if typeof options.hsqldb.group is 'string'
  options.hsqldb.group ?= {}
  options.hsqldb.group.name ?= 'hsqldb'
  options.hsqldb.group.system ?= true
  # User
  options.hsqldb.user = name: options.hsqldb.user if typeof options.hsqldb.user is 'string'
  options.hsqldb.user ?= {}
  options.hsqldb.user.name ?= 'hsqldb'
  options.hsqldb.user.system ?= true
  options.hsqldb.user.gid = 'hsqldb'
  options.hsqldb.user.shell = false
  options.hsqldb.user.comment ?= 'LDAP User'
  options.hsqldb.user.home = '/var/lib/hsqldb'

  # Group
  options.apache ?= {}
  options.apache.group = name: options.apache.group if typeof options.apache.group is 'string'
  options.apache.group ?= {}
  options.apache.group.name ?= 'apache'
  options.apache.group.system ?= true
  # User
  options.apache.user = name: options.apache.user if typeof options.apache.user is 'string'
  options.apache.user ?= {}
  options.apache.user.name ?= 'apache'
  options.apache.user.system ?= true
  options.apache.user.gid = 'apache'
  options.apache.user.shell = false
  options.apache.user.comment ?= 'apache User'
  options.apache.user.home = '/usr/share/httpd'

  # Group
  options.memcached ?= {}
  options.memcached.group = name: options.memcached.group if typeof options.memcached.group is 'string'
  options.memcached.group ?= {}
  options.memcached.group.name ?= 'memcached'
  options.memcached.group.system ?= true
  # User
  options.memcached.user = name: options.memcached.user if typeof options.memcached.user is 'string'
  options.memcached.user ?= {}
  options.memcached.user.name ?= 'memcached'
  options.memcached.user.system ?= true
  options.memcached.user.gid = 'memcached'
  options.memcached.user.shell = false
  options.memcached.user.comment ?= 'memcached User'
  options.memcached.user.home = '/run/memcached'
  # Group
  options.ods ?= {}
  options.ods.group = name: options.ods.group if typeof options.ods.group is 'string'
  options.ods.group ?= {}
  options.ods.group.name ?= 'ods'
  options.ods.group.system ?= true
  # User
  options.ods.user = name: options.ods.user if typeof options.ods.user is 'string'
  options.ods.user ?= {}
  options.ods.user.name ?= 'ods'
  options.ods.user.system ?= true
  options.ods.user.gid = 'ods'
  options.ods.user.shell = false
  options.ods.user.comment ?= 'ods User'
  options.ods.user.home = '/var/lib/softhsm'
  # Group
  options.tomcat ?= {}
  options.tomcat.group = name: options.tomcat.group if typeof options.tomcat.group is 'string'
  options.tomcat.group ?= {}
  options.tomcat.group.name ?= 'tomcat'
  options.tomcat.group.system ?= true
  # User
  options.tomcat.user = name: options.tomcat.user if typeof options.tomcat.user is 'string'
  options.tomcat.user ?= {}
  options.tomcat.user.name ?= 'tomcat'
  options.tomcat.user.system ?= true
  options.tomcat.user.gid = 'tomcat'
  options.tomcat.user.shell = false
  options.tomcat.user.comment ?= 'tomcat User'
  options.tomcat.user.home = '/usr/share/tomcat'
  # Group
  options.pkiuser ?= {}
  options.pkiuser.group = name: options.pkiuser.group if typeof options.pkiuser.group is 'string'
  options.pkiuser.group ?= {}
  options.pkiuser.group.name ?= 'pkiuser'
  options.pkiuser.group.system ?= true
  # User
  options.pkiuser.user = name: options.pkiuser.user if typeof options.pkiuser.user is 'string'
  options.pkiuser.user ?= {}
  options.pkiuser.user.name ?= 'pkiuser'
  options.pkiuser.user.system ?= true
  options.pkiuser.user.gid = 'pkiuser'
  options.pkiuser.user.shell = false
  options.pkiuser.user.comment ?= 'pkiuser User'
  options.pkiuser.user.home = '/usr/share/pki'
  # Group
  options.dirsrv ?= {}
  options.dirsrv.group = name: options.dirsrv.group if typeof options.dirsrv.group is 'string'
  options.dirsrv.group ?= {}
  options.dirsrv.group.name ?= 'dirsrv'
  options.dirsrv.group.system ?= true
  # User
  options.dirsrv.user = name: options.dirsrv.user if typeof options.dirsrv.user is 'string'
  options.dirsrv.user ?= {}
  options.dirsrv.user.name ?= 'dirsrv'
  options.dirsrv.user.system ?= true
  options.dirsrv.user.gid = 'dirsrv'
  options.dirsrv.user.shell = false
  options.dirsrv.user.comment ?= 'dirsrv User'
  options.dirsrv.user.home = '/usr/share/dirsrv'
  # Configuration
  options.iptables ?= deps.iptables and deps.iptables.options.action is 'start'
  options.conf_dir ?= '/etc/freeipa/conf'
  # Prepare configuration for "kdc.conf"
  throw Error 'Required Manager Password "manager_password"' unless options.manager_password?
  throw Error '"manager_password" should be 8 characters long' unless options.manager_password.length > 7
  throw Error 'Required Admin Password "admin_password"' unless options.admin_password?
  throw Error '"admin_password" should be 8 characters long' unless options.admin_password.length > 7
  # Modules
  # DNS
  options.dns_enabled ?= true
  options.dns ?= {}
  if options.dns_enabled
    throw Error 'Missing domain name "domain"' unless options.domain?
    throw Error 'Missing dns manager email "dns_email_manager"' unless options.dns_email_manager?
    options.dns_auto_reverse ?= true
    options.dns_auto_forward ?= false
    options.dns_forwarder ?= []
    options.dns_forwarder = [options.dns_forwarder] unless Array.isArray options.dns_forwarder
  # NTP
  options.ntp_enabled ?= true
  # KERBEROS
  options.realm_name ?= options.domain.toUpperCase()
  throw Error 'Missing realm name "realm_name"' unless options.realm_name?
  # SSL
  options.ssl_enabled ?= true
  if options.ssl_enabled
    if options.external_ca
      options.ca_subject ?= "CN=Certificate Authority,O=#{option.realm_name}"
    else
      throw Error 'SSL/TLS mode requires "ssl_cert_file"' unless options.ssl_cert_file
      throw Error 'SSL/TLS mode requires "ssl_key_file"' unless options.ssl_key_file
      options.ssl_key_local ?= true
      options.ssl_ca_cert_local ?= true
  # Client Admin Operation
  options.admin ?= {}
  options.admin[options.realm_name] ?=
    realm: options.realm_name
    kadmin_principal: "admin@#{options.realm_name}"
    kadmin_password: options.admin_password
  # Wait
  options.wait = {}
