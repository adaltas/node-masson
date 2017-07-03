
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
      options = @config.mariadb ?= {}
      {ssl} = @config
      options.server ?= {}
      # User SQL
      options.server.sql_on_install ?= []
      options.server.sql_on_install = [options.server.sql_on_install] if typeof options.server.sql_on_install is 'string'
      # Secure Installation
      options.server.current_password ?= ''
      options.server.password ?= ''
      options.server.remove_anonymous ?= true
      options.server.disallow_remote_root_login ?= false
      options.server.remove_test_db ?= true
      options.server.reload_privileges ?= true
      # Service Configuration
      options.server.group ?= name: 'mysql'
      options.server.group = name: options.server.group if typeof options.server.group is 'string'
      options.server.user ?= name: 'mysql'
      options.server.user = name: options.server.user if typeof options.server.user is 'string'
      options.server.user.home ?= "/var/lib/#{options.server.user.name}"
      options.server.user.gid = options.server.group.name
      options.server.my_cnf ?= {}
      options.server.my_cnf['mysqld'] ?= {}

## High Availability
Mysql does support HA it is a Master/Slave HA. If DBAs needs Master/Master style replication
Master/Slave replication should be set up in both directions.
If the DBA need more than two Masters, Ring like architecture should be used.
[mysql-properties]:(http://dev.options.com/doc/refman/5.7/en/replication-options-slave.html)

Note: For Now Ryba does not support automatic discovery for more than 2 master.

      options.ha_enabled ?= if mysql_ctxs.length > 1 then true else false
      if options.ha_enabled
        options.replication_dir ?= "#{options.server.user.home}/replication"
        mysql_hosts = mysql_ctxs.map (ctx) -> ctx.config.host
        # Attribute an id to mysql server
        # This line is to be changed by admin to set replication architecture.
        options.server.id ?= mysql_hosts.indexOf(@config.host)+1
        options.server.my_cnf['mysqld']['server-id'] = options.server.id
        # automatic discovery
        # for ryba each mysql sever is a master, for enabling the replication,
        # a slave host hould be defined.
        if mysql_ctxs.length is 2
          options.server.repl_master ?= {}
          options.server.repl_master.host ?= mysql_hosts.filter( (host) => host isnt @config.host)[0]
          options.server.repl_master.user ?= 'repl'
          options.server.repl_master.pwd ?= 'repl123'
        else
          throw Error 'No slave configured' unless options.server.repl_master?.host?
        # attribute a the master and check if every mster has unique id
        options.server.my_cnf['mysqld']['relay-log'] ?= "#{options.replication_dir}/mysql-relay-bin"
        options.server.my_cnf['mysqld']['relay-log-index'] ?= "#{options.replication_dir}/mysql-relay-bin.index"
        options.server.my_cnf['mysqld']['master-info-file'] ?= "#{options.replication_dir}/master.info"
        options.server.my_cnf['mysqld']['relay-log-info-file'] ?= "#{options.replication_dir}/relay-log.info"
        options.server.my_cnf['mysqld']['log-slave-updates'] ?= ''
        options.server.my_cnf['mysqld']['replicate-same-server-id'] ?= '0'
        options.server.my_cnf['mysqld']['slave-skip-errors'] = '1062' #skip all duplicate errors you might be getting

### Journalisation

      options.journal_log_dir ?= "#{options.server.user.home}/log"
      options.server.my_cnf['mysqld']['general_log'] ?= 'OFF'
      options.server.my_cnf['mysqld']['general_log_file'] ?= "#{options.journal_log_dir}/log-general.log"
      options.server.my_cnf['mysqld']['log-bin'] ?= "#{options.journal_log_dir}/bin"
      options.server.my_cnf['mysqld']['binlog_format'] ?= 'mixed'

### General

      options.server.my_cnf['mysqld']['port'] ?= '3306'
      # Note bind address mut be an ip adress and not a hostname
      options.server.my_cnf['mysqld']['bind-address'] ?= '0.0.0.0'
      options.server.my_cnf['mysqld']['pid-file'] ?= '/var/run/mysql/options.pid'
      options.server.my_cnf['mysqld']['socket'] ?= '/var/lib/mysql/mysql.sock'
      options.server.my_cnf['mysqld']['datadir'] ?= "#{options.server.user.home}/data"
      options.server.my_cnf['mysqld']['user'] ?= "#{options.server.user.name}"
      options.server.my_cnf['mysqld']['event_scheduler'] ?= 'ON'
      options.server.my_cnf['mysqld']['character-set-server'] ?= 'latin1'
      options.server.my_cnf['mysqld']['collation-server'] ?= 'latin1_swedish_ci'
      options.server.my_cnf['mysqld']['skip-external-locking'] ?= ''
      options.server.my_cnf['mysqld']['key_buffer_size'] ?= '384M'
      options.server.my_cnf['mysqld']['max_allowed_packet'] ?= '1M'
      options.server.my_cnf['mysqld']['table_open_cache'] ?= '512'
      options.server.my_cnf['mysqld']['sort_buffer_size'] ?= '2M'
      options.server.my_cnf['mysqld']['read_buffer_size'] ?= '2M'
      options.server.my_cnf['mysqld']['read_rnd_buffer_size'] ?= '8M'
      options.server.my_cnf['mysqld']['myisam_sort_buffer_size'] ?= '64M'
      options.server.my_cnf['mysqld']['thread_cache_size'] ?= '8'
      options.server.my_cnf['mysqld']['query_cache_size'] ?= '32M'

### Auth

      options.server.my_cnf['mysqld']['secure-auth'] ?= ''
      options.server.my_cnf['mysqld']['secure-file-priv'] ?="#{options.server.user.home}/upload"
      options.server.my_cnf['mysqld']['max_connections'] ?= '100'
      options.server.my_cnf['mysqld']['max_user_connections'] ?= '50'
      options.server.my_cnf['mysqld']['log-error'] ?= '/var/log/mysqld/error.log'
      options.server.my_cnf['mysqld']['slow_query_log_file'] ?= "#{options.journal_log_dir}/slow-queries.log"
      options.server.my_cnf['mysqld']['long_query_time'] ?= '4'
      options.server.my_cnf['mysqld']['expire_logs_days'] ?= '7'

### InnoDB Configuration

      options.server.my_cnf['mysqld']['innodb_file_per_table'] ?= ''
      options.server.my_cnf['mysqld']['innodb_data_home_dir'] ?= "#{options.server.user.home}/data"
      options.server.my_cnf['mysqld']['innodb_data_file_path'] ?= 'ibdata1:10M:autoextend'
      options.server.my_cnf['mysqld']['innodb_log_group_home_dir'] ?= "#{options.journal_log_dir}"
      options.server.my_cnf['mysqld']['innodb_buffer_pool_size'] ?= '384M'
      # options.server.my_cnf['mysqld']['innodb_additional_mem_pool_size'] ?= '20M'
      options.server.my_cnf['mysqld']['innodb_log_file_size'] ?= '100M'
      options.server.my_cnf['mysqld']['innodb_log_buffer_size'] ?= '8M'
      options.server.my_cnf['mysqld']['innodb_flush_log_at_trx_commit'] ?= '1'
      options.server.my_cnf['mysqld']['innodb_lock_wait_timeout'] ?= '50'
      
### SSL

      options.ssl ?= ssl
      if options.ssl
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        options.server.my_cnf['mysqld']['ssl-ca'] ?= "#{options.server.user.home}/data/ca.pem"
        options.server.my_cnf['mysqld']['ssl-cert'] ?= "#{options.server.user.home}/data/server-cert.pem"
        options.server.my_cnf['mysqld']['ssl-key'] ?= "#{options.server.user.home}/data/server-key.pem"

## MySQL Dump

      options.server.my_cnf['mysqldump'] ?= {}
      options.server.my_cnf['mysqldump']['quick'] ?= ''
      options.server.my_cnf['mysqldump']['max_allowed_packet'] ?= '16M'

## MySQL

      options.server.my_cnf['mysql'] ?= {}
      options.server.my_cnf['mysql']['no-auto-rehash'] ?= ''

## MyISAM Check

      options.server.my_cnf['myisamchk'] ?= {}
      options.server.my_cnf['myisamchk']['key_buffer_size'] ?= '256M'
      options.server.my_cnf['myisamchk']['sort_buffer_size'] ?= '256M'
      options.server.my_cnf['myisamchk']['read_buffer'] ?= '2M'
      options.server.my_cnf['myisamchk']['write_buffer'] ?= '2M'

## Hot Copy

      options.server.my_cnf['mysqlhotcopy'] ?= {}
      options.server.my_cnf['mysqlhotcopy']['interactive-timeout'] ?= ''

## Client
      
      options.server.my_cnf['client'] ?= {}
      options.server.my_cnf['client']['socket'] ?= options.server.my_cnf['mysqld']['socket']

## Safe
      
      options.server.my_cnf['mysqld_safe'] ?= {}
      options.server.my_cnf['mysqld_safe']['pid-file'] = options.server.my_cnf['mysqld']['pid-file']

## Repo
      
      options.repo ?= {}
      options.repo.source ?= null
      options.repo.target ?= 'mariadb.repo'
      options.repo.target = path.resolve '/etc/yum.repos.d', options.repo.target
      options.repo.replace ?= 'mariadb*'


## Dependencies

    path = require 'path'
