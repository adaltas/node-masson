
# MariaDB Server Configure

*   `sql_on_install` (array|string)
*   `current_password` (string)
*   `password` (string)
*   `remove_anonymous` (boolean)
*   `disallow_remote_root_login` (boolean)
*   `remove_test_db` (boolean)
*   `reload_privileges` (boolean)
*   `my_cnf` (object)
    Object to be serialized into the "ini" format inside "/etc/my.cnf"

Default configuration:

```
{ "mysql": {
  "server": {
    "sql_on_install": [],
    "current_password": "",
    "password": "",
    "remove_anonymous": true,
    "disallow_remote_root_login": false,
    "remove_test_db": true,
    "reload_privileges": true,
    "my_cnf": {
      "mysqld": {
        "tmpdir": "/tmp/mysql"
      }
    }
  }
}
```

    module.exports = (service) ->
      options = service.options
      
## Environment

      # User SQL
      options.sql_on_install ?= []
      options.sql_on_install = [options.sql_on_install] if typeof options.sql_on_install is 'string'
      # Secure Installation
      options.current_password ?= ''
      options.admin_username ?= 'root'
      throw Error 'Required Option: admin_password' unless options.admin_password
      # options.password ?= ''
      options.remove_anonymous ?= true
      options.disallow_remote_root_login ?= false
      options.remove_test_db ?= true
      options.reload_privileges ?= true
      options.fqdn ?= service.node.fqdn
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'mysql'
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'mysql'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.gid ?= options.group.name

## Service
parametrize service options as the name depends on how the service is installed.
      
      options.name ?= 'mariadb-server'
      options.srv_name ?= 'mariadb'
      options.chk_name ?= 'mariadb'

## Configuration

      options.my_cnf ?= {}
      options.my_cnf['mysqld'] ?= {}

## High Availability
Mysql does support HA it is a Master/Slave HA. If DBAs needs Master/Master style replication
Master/Slave replication should be set up in both directions.
If the DBA need more than two Masters, Ring like architecture should be used.
[mysql-properties]:(http://dev.g.com/doc/refman/5.7/en/replication-options-slave.html)

Note: For Now Ryba does not support automatic discovery for more than 2 master.

      options.ha_enabled ?= if service.deps.mariadb.length > 1 then true else false
      if options.ha_enabled
        throw Error "Invalid HA Configuration: expect only 2 nodes" unless service.deps.mariadb.length is 2
        options.replication_dir ?= "#{options.user.home}/replication"
        mysql_fqdns = service.deps.mariadb.map( (srv) -> srv.node.fqdn ).sort()
        # Attribute an id to mysql server
        # This line is to be changed by admin to set replication architecture.
        options.id ?= mysql_fqdns.indexOf(service.node.fqdn)+1
        options.my_cnf['mysqld']['server-id'] = options.id
        # automatic discovery
        # for ryba each mysql sever is a master, for enabling the replication,
        # a slave host hould be defined.
        for mariadb_srv in service.deps.mariadb
          continue if mariadb_srv.node.fqdn is service.node.fqdn
          options.repl_master ?= {}
          options.repl_master.fqdn ?= mariadb_srv.node.fqdn
          options.repl_master.admin_username ?= mariadb_srv.options.admin_username or 'root'
          options.repl_master.admin_password ?= mariadb_srv.options.admin_password or throw Error "Required Option: admin_password"
          mariadb_srv.options.repl_master ?= {}
          options.repl_master.username ?= mariadb_srv.options.repl_master.username or 'repl'
          options.repl_master.password ?= mariadb_srv.options.repl_master.password or throw Error "Required Option: repl_master.password"
        throw Error 'No slave configured' unless options.repl_master.fqdn
        # attribute a the master and check if every mster has unique id
        options.my_cnf['mysqld']['relay-log'] ?= "#{options.replication_dir}/mysql-relay-bin"
        options.my_cnf['mysqld']['relay-log-index'] ?= "#{options.replication_dir}/mysql-relay-bin.index"
        options.my_cnf['mysqld']['master-info-file'] ?= "#{options.replication_dir}/master.info"
        options.my_cnf['mysqld']['relay-log-info-file'] ?= "#{options.replication_dir}/relay-log.info"
        options.my_cnf['mysqld']['log-slave-updates'] ?= ''
        options.my_cnf['mysqld']['replicate-same-server-id'] ?= '0'
        options.my_cnf['mysqld']['slave-skip-errors'] = '1062' #skip all duplicate errors you might be getting

### Journalisation

      options.journal_log_dir ?= "#{options.user.home}/log"
      options.my_cnf['mysqld']['general_log'] ?= 'OFF'
      options.my_cnf['mysqld']['general_log_file'] ?= "#{options.journal_log_dir}/log-general.log"
      options.my_cnf['mysqld']['log-bin'] ?= "#{options.journal_log_dir}/bin"
      options.my_cnf['mysqld']['binlog_format'] ?= 'mixed'

### General

      options.my_cnf['mysqld']['port'] ?= '3306'
      # Note bind address mut be an ip adress and not a hostname
      options.my_cnf['mysqld']['bind-address'] ?= '0.0.0.0'
      options.my_cnf['mysqld']['pid-file'] ?= '/var/run/mysql/options.pid'
      options.my_cnf['mysqld']['socket'] ?= '/var/lib/mysql/mysql.sock'
      options.my_cnf['mysqld']['datadir'] ?= "#{options.user.home}/data"
      options.my_cnf['mysqld']['user'] ?= "#{options.user.name}"
      options.my_cnf['mysqld']['event_scheduler'] ?= 'ON'
      options.my_cnf['mysqld']['character-set-server'] ?= 'latin1'
      options.my_cnf['mysqld']['collation-server'] ?= 'latin1_swedish_ci'
      options.my_cnf['mysqld']['skip-external-locking'] ?= ''
      options.my_cnf['mysqld']['key_buffer_size'] ?= '384M'
      options.my_cnf['mysqld']['max_allowed_packet'] ?= '1M'
      options.my_cnf['mysqld']['table_open_cache'] ?= '512'
      options.my_cnf['mysqld']['sort_buffer_size'] ?= '2M'
      options.my_cnf['mysqld']['read_buffer_size'] ?= '2M'
      options.my_cnf['mysqld']['read_rnd_buffer_size'] ?= '8M'
      options.my_cnf['mysqld']['myisam_sort_buffer_size'] ?= '64M'
      options.my_cnf['mysqld']['thread_cache_size'] ?= '8'
      options.my_cnf['mysqld']['query_cache_size'] ?= '32M'

### Auth

      options.my_cnf['mysqld']['secure-auth'] ?= ''
      options.my_cnf['mysqld']['secure-file-priv'] ?="#{options.user.home}/upload"
      options.my_cnf['mysqld']['max_connections'] ?= '100'
      options.my_cnf['mysqld']['max_user_connections'] ?= '50'
      options.my_cnf['mysqld']['log-error'] ?= '/var/log/mysqld/error.log'
      options.my_cnf['mysqld']['slow_query_log_file'] ?= "#{options.journal_log_dir}/slow-queries.log"
      options.my_cnf['mysqld']['long_query_time'] ?= '4'
      options.my_cnf['mysqld']['expire_logs_days'] ?= '7'

### InnoDB Configuration

      options.my_cnf['mysqld']['innodb_file_per_table'] ?= ''
      options.my_cnf['mysqld']['innodb_data_home_dir'] ?= "#{options.user.home}/data"
      options.my_cnf['mysqld']['innodb_data_file_path'] ?= 'ibdata1:10M:autoextend'
      options.my_cnf['mysqld']['innodb_log_group_home_dir'] ?= "#{options.journal_log_dir}"
      options.my_cnf['mysqld']['innodb_buffer_pool_size'] ?= '384M'
      # options.my_cnf['mysqld']['innodb_additional_mem_pool_size'] ?= '20M'
      options.my_cnf['mysqld']['innodb_log_file_size'] ?= '100M'
      options.my_cnf['mysqld']['innodb_log_buffer_size'] ?= '8M'
      options.my_cnf['mysqld']['innodb_flush_log_at_trx_commit'] ?= '1'
      options.my_cnf['mysqld']['innodb_lock_wait_timeout'] ?= '50'

### SSL

      options.ssl ?= service.deps.ssl?.options
      if options.ssl
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cert" if not options.ssl.cert
        options.my_cnf['mysqld']['ssl-ca'] ?= "#{options.user.home}/data/ca.pem"
        options.my_cnf['mysqld']['ssl-cert'] ?= "#{options.user.home}/data/server-cert.pem"
        options.my_cnf['mysqld']['ssl-key'] ?= "#{options.user.home}/data/server-key.pem"

## MySQL Dump

      options.my_cnf['mysqldump'] ?= {}
      options.my_cnf['mysqldump']['quick'] ?= ''
      options.my_cnf['mysqldump']['max_allowed_packet'] ?= '16M'

## MySQL

      options.my_cnf['mysql'] ?= {}
      options.my_cnf['mysql']['no-auto-rehash'] ?= ''

## MyISAM Check

      options.my_cnf['myisamchk'] ?= {}
      options.my_cnf['myisamchk']['key_buffer_size'] ?= '256M'
      options.my_cnf['myisamchk']['sort_buffer_size'] ?= '256M'
      options.my_cnf['myisamchk']['read_buffer'] ?= '2M'
      options.my_cnf['myisamchk']['write_buffer'] ?= '2M'

## Hot Copy

      options.my_cnf['mysqlhotcopy'] ?= {}
      options.my_cnf['mysqlhotcopy']['interactive-timeout'] ?= ''

## Client

      options.my_cnf['client'] ?= {}
      options.my_cnf['client']['socket'] ?= options.my_cnf['mysqld']['socket']

## Safe

      options.my_cnf['mysqld_safe'] ?= {}
      options.my_cnf['mysqld_safe']['pid-file'] = options.my_cnf['mysqld']['pid-file']

## Repo

      options.repo ?= {}
      options.repo.source ?= null
      options.repo.target ?= 'mariadb.repo'
      options.repo.target = path.resolve '/etc/yum.repos.d', options.repo.target
      options.repo.replace ?= 'mariadb*'

## Wait

      options.wait_tcp = {}
      options.wait_tcp.fqdn = service.node.fqdn
      options.wait_tcp.port = options.my_cnf['mysqld']['port']

## Dependencies

    path = require 'path'
