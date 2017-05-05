
# Mysql Server Configure

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

    module.exports = ->
      mysql_ctxs = @contexts 'masson/commons/mariadb/server'
      mysql = @config.mysql ?= {}
      mysql.server ?= {}
      # User SQL
      mysql.server.sql_on_install ?= []
      mysql.server.sql_on_install = [mysql.server.sql_on_install] if typeof mysql.server.sql_on_install is 'string'
      # Secure Installation
      mysql.server.current_password ?= ''
      mysql.server.password ?= ''
      mysql.server.remove_anonymous ?= true
      mysql.server.disallow_remote_root_login ?= false
      mysql.server.remove_test_db ?= true
      mysql.server.reload_privileges ?= true
      # Service Configuration
      mysql.server.group ?= name: 'mysql'
      mysql.server.group = name: mysql.server.group if typeof mysql.server.group is 'string'
      mysql.server.user ?= name: 'mysql'
      mysql.server.user = name: mysql.server.user if typeof mysql.server.user is 'string'
      mysql.server.user.home ?= "/var/lib/#{mysql.server.user.name}"
      mysql.server.user.gid = mysql.server.group.name
      mysql.server.my_cnf ?= {}
      mysql.server.my_cnf['mysqld'] ?= {}

## High Availability
Mysql does support HA it is a Master/Slave HA. If DBAs needs Master/Master style replication
Master/Slave replication should be set up in both directions.
If the DBA need more than two Masters, Ring like architecture should be used.
[mysql-properties]:(http://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html)

Note: For Now Ryba does not support automatic discovery for more than 2 master.

      mysql.ha_enabled ?= if mysql_ctxs.length > 1 then true else false
      if mysql.ha_enabled
        mysql.replication_dir ?= "#{mysql.server.user.home}/replication"
        mysql_hosts = mysql_ctxs.map (ctx) -> ctx.config.host
        # Attribute an id to mysql server
        # This line is to be changed by admin to set replication architecture.
        mysql.server.id ?= mysql_hosts.indexOf(@config.host)+1
        mysql.server.my_cnf['mysqld']['server-id'] = mysql.server.id
        # automatic discovery
        # for ryba each mysql sever is a master, for enabling the replication,
        # a slave host hould be defined.
        if mysql_ctxs.length is 2
          mysql.server.repl_master ?= {}
          mysql.server.repl_master.host ?= mysql_hosts.filter( (host) => host isnt @config.host)[0]
          mysql.server.repl_master.user ?= 'repl'
          mysql.server.repl_master.pwd ?= 'repl123'
        else
          throw Error 'No slave configured' unless mysql.server.repl_master?.host?
        # attribute a the master and check if every mster has unique id
        mysql.server.my_cnf['mysqld']['relay-log'] ?= "#{mysql.replication_dir}/mysql-relay-bin"
        mysql.server.my_cnf['mysqld']['relay-log-index'] ?= "#{mysql.replication_dir}/mysql-relay-bin.index"
        mysql.server.my_cnf['mysqld']['master-info-file'] ?= "#{mysql.replication_dir}/master.info"
        mysql.server.my_cnf['mysqld']['relay-log-info-file'] ?= "#{mysql.replication_dir}/relay-log.info"
        mysql.server.my_cnf['mysqld']['log-slave-updates'] ?= ''
        mysql.server.my_cnf['mysqld']['replicate-same-server-id'] ?= '0'
        mysql.server.my_cnf['mysqld']['slave-skip-errors'] = '1062' #skip all duplicate errors you might be getting

### Journalisation

      mysql.journal_log_dir ?= "#{mysql.server.user.home}/log"
      mysql.server.my_cnf['mysqld']['general_log'] ?= 'OFF'
      mysql.server.my_cnf['mysqld']['general_log_file'] ?= "#{mysql.journal_log_dir}/log-general.log"
      mysql.server.my_cnf['mysqld']['log-bin'] ?= "#{mysql.journal_log_dir}/bin"
      mysql.server.my_cnf['mysqld']['binlog_format'] ?= 'mixed'

### General

      mysql.server.my_cnf['mysqld']['port'] ?= '3306'
      # Note bind address mut be an ip adress and not a hostname
      mysql.server.my_cnf['mysqld']['bind-address'] ?= '0.0.0.0'
      mysql.server.my_cnf['mysqld']['pid-file'] ?= '/var/run/mysql/mysql.pid'
      mysql.server.my_cnf['mysqld']['socket'] ?= '/var/lib/mysql/mysql.sock'
      mysql.server.my_cnf['mysqld']['datadir'] ?= "#{mysql.server.user.home}/data"
      mysql.server.my_cnf['mysqld']['user'] ?= "#{mysql.server.user.name}"
      mysql.server.my_cnf['mysqld']['event_scheduler'] ?= 'ON'
      mysql.server.my_cnf['mysqld']['character-set-server'] ?= 'latin1'
      mysql.server.my_cnf['mysqld']['collation-server'] ?= 'latin1_swedish_ci'
      mysql.server.my_cnf['mysqld']['skip-external-locking'] ?= ''
      mysql.server.my_cnf['mysqld']['key_buffer_size'] ?= '384M'
      mysql.server.my_cnf['mysqld']['max_allowed_packet'] ?= '1M'
      mysql.server.my_cnf['mysqld']['table_open_cache'] ?= '512'
      mysql.server.my_cnf['mysqld']['sort_buffer_size'] ?= '2M'
      mysql.server.my_cnf['mysqld']['read_buffer_size'] ?= '2M'
      mysql.server.my_cnf['mysqld']['read_rnd_buffer_size'] ?= '8M'
      mysql.server.my_cnf['mysqld']['myisam_sort_buffer_size'] ?= '64M'
      mysql.server.my_cnf['mysqld']['thread_cache_size'] ?= '8'
      mysql.server.my_cnf['mysqld']['query_cache_size'] ?= '32M'

### Auth

      mysql.server.my_cnf['mysqld']['secure-auth'] ?= ''
      mysql.server.my_cnf['mysqld']['secure-file-priv'] ?="#{mysql.server.user.home}/upload"
      mysql.server.my_cnf['mysqld']['max_connections'] ?= '100'
      mysql.server.my_cnf['mysqld']['max_user_connections'] ?= '50'
      mysql.server.my_cnf['mysqld']['log-error'] ?= '/var/log/mysqld/error.log'
      mysql.server.my_cnf['mysqld']['slow_query_log_file'] ?= "#{mysql.journal_log_dir}/slow-queries.log"
      mysql.server.my_cnf['mysqld']['long_query_time'] ?= '4'
      mysql.server.my_cnf['mysqld']['expire_logs_days'] ?= '7'

### InnoDB Configuration

      mysql.server.my_cnf['mysqld']['innodb_file_per_table'] ?= ''
      mysql.server.my_cnf['mysqld']['innodb_data_home_dir'] ?= "#{mysql.server.user.home}/data"
      mysql.server.my_cnf['mysqld']['innodb_data_file_path'] ?= 'ibdata1:10M:autoextend'
      mysql.server.my_cnf['mysqld']['innodb_log_group_home_dir'] ?= "#{mysql.journal_log_dir}"
      mysql.server.my_cnf['mysqld']['innodb_buffer_pool_size'] ?= '384M'
      mysql.server.my_cnf['mysqld']['innodb_additional_mem_pool_size'] ?= '20M'
      mysql.server.my_cnf['mysqld']['innodb_log_file_size'] ?= '100M'
      mysql.server.my_cnf['mysqld']['innodb_log_buffer_size'] ?= '8M'
      mysql.server.my_cnf['mysqld']['innodb_flush_log_at_trx_commit'] ?= '1'
      mysql.server.my_cnf['mysqld']['innodb_lock_wait_timeout'] ?= '50'
      
### SSL

      mysql.tls ?= true
      if mysql.tls
        mysql.server.my_cnf['mysqld']['ssl-ca'] ?= "#{mysql.server.user.home}/data/ca.pem"
        mysql.server.my_cnf['mysqld']['ssl-cert'] ?= "#{mysql.server.user.home}/data/server-cert.pem"
        mysql.server.my_cnf['mysqld']['ssl-key'] ?= "#{mysql.server.user.home}/data/server-key.pem"

## MySQL Dump

      mysql.server.my_cnf['mysqldump'] ?= {}
      mysql.server.my_cnf['mysqldump']['quick'] ?= ''
      mysql.server.my_cnf['mysqldump']['max_allowed_packet'] ?= '16M'

## MySQL

      mysql.server.my_cnf['mysql'] ?= {}
      mysql.server.my_cnf['mysql']['no-auto-rehash'] ?= ''

## MyISAM Check

      mysql.server.my_cnf['myisamchk'] ?= {}
      mysql.server.my_cnf['myisamchk']['key_buffer_size'] ?= '256M'
      mysql.server.my_cnf['myisamchk']['sort_buffer_size'] ?= '256M'
      mysql.server.my_cnf['myisamchk']['read_buffer'] ?= '2M'
      mysql.server.my_cnf['myisamchk']['write_buffer'] ?= '2M'

## Hot Copy

      mysql.server.my_cnf['mysqlhotcopy'] ?= {}
      mysql.server.my_cnf['mysqlhotcopy']['interactive-timeout'] ?= ''

## Client
      
      mysql.server.my_cnf['client'] ?= {}
      mysql.server.my_cnf['client']['socket'] ?= mysql.server.my_cnf['mysqld']['socket']

## Safe
      
      mysql.server.my_cnf['mysqld_safe'] ?= {}
      mysql.server.my_cnf['mysqld_safe']['pid-file'] = mysql.server.my_cnf['mysqld']['pid-file']
