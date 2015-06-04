
# Mysql Server

    each = require 'each'
    escape = (text) -> text.replace(/[\\"]/g, "\\$&")
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/iptables'
    exports.push 'masson/commons/mysql_client' # Install the mysql driver

## Configure


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

    exports.push module.exports.configure = (ctx) ->
      require('../core/iptables').configure ctx
      mysql = ctx.config.mysql ?= {}

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
      mysql.server.my_cnf ?= {}
      mysql.server.my_cnf['mysqld'] ?= {}
      mysql.server.my_cnf['mysqld']['tmpdir'] ?= '/tmp/mysql'

      mysql.user ?= name: 'mysql'
      mysql.user = name: mysql.user if typeof mysql.user is 'string'
      mysql.group ?= name: 'mysql'
      mysql.group = name: mysql.group if typeof mysql.group is 'string'

## IPTables

| Service    | Port | Proto | Parameter |
|------------|------|-------|-----------|
| MySQL      | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

    exports.push name: 'Mysql Server # IPTables', handler: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3306, protocol: 'tcp', state: 'NEW', comment: "MySQL" }
        ]
        if: ctx.config.iptables.action is 'start'
      , next

## Package

Install the Mysql database server. Secure the temporary directory.

    exports.push name: 'Mysql Server # Package', timeout: -1, handler: (ctx, next) ->
      {user, group, server} = ctx.config.mysql
      modified = false
      do_install = ->
        ctx.service
          name: 'mysql-server'
          chk_name: 'mysqld'
          startup: '235'
        , (err, serviced) ->
          return next err if err
          modified = true if serviced
          do_tmp()
      do_tmp = ->
        ctx.mkdir
          destination: '/tmp/mysql'
          uid: user.name
          gid: group.name
          mode: '0744'
        , (err, created) ->
          return next err if err
          modified = true if created
          ctx.ini
            destination: '/etc/my.cnf'
            content: server.my_cnf
            merge: true
            backup: true
          , (err, updated) ->
            return next err if err
            modified = true if updated
            do_end()
      do_end = ->
        next null, modified
      do_install()

    exports.push name: 'Mysql Server # Start', handler: (ctx, next) ->
      modified = false
      do_start = ->
        ctx.service
          name: 'mysql-server'
          srv_name: 'mysqld'
          action: 'start'
        , (err, started) ->
          # return next err if err
          return do_clean_sock() if err
          modified = true if started
          do_end()
      do_clean_sock = ->
        console.log 'do_clean_sock'
        ctx.remove
          destination: "/var/lib/mysql/mysql.sock"
        , (err, removed) ->
          return next err if err
          return next new Error 'Failed to install mysqld' unless removed
          ctx.service_start
            name: 'mysqld'
            action: 'start'
          , (err, started) ->
            return next err if err
            modified = true if started
            do_end()
      do_end = ->
        next null, modified
      do_start()

    exports.push name: 'Mysql Server # Populate', handler: (ctx, next) ->
      {sql_on_install} = ctx.config.mysql.server
      each(sql_on_install)
      .on 'item', (sql, next) ->
        cmd = "mysql -uroot -e \"#{escape sql}\""
        ctx.log "Execute: #{cmd}"
        ctx.execute
          cmd: cmd
          code_skipped: 1
        , (err, executed) ->
          return next err if err
          modified = true if executed
          next()
      .on 'both', (err) ->
        next err, false

## Secure Installation

/usr/bin/mysql_secure_installation (run as root after install).
Enter current password for root (enter for none):
Set root password? [Y/n] y
>> big123
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] n
Remove test database and access to it? [Y/n] y

    exports.push name: 'Mysql Server # Secure', handler: (ctx, next) ->
      {current_password, password, remove_anonymous, disallow_remote_root_login, remove_test_db, reload_privileges} = ctx.config.mysql.server
      test_password = true
      modified = false
      ctx.ssh.shell (err, stream) ->
        stream.write '/usr/bin/mysql_secure_installation\n'
        data = ''
        error = exit = null
        stream.on 'data', (data, extended) ->
          ctx.log[if extended is 'stderr' then 'err' else 'out'].write data
          switch
            when /Enter current password for root/.test data
              stream.write "#{if test_password then password else current_password}\n"
              data = ''
            when /ERROR 1045/.test(data) and test_password
              test_password = false
              modified = true
              data = ''
            when /Change the root password/.test data
              stream.write "y\n"
              data = ''
            when /Set root password/.test data
              stream.write "y\n"
              data = ''
            when /New password/.test(data) or /Re-enter new password/.test(data)
              stream.write "#{password}\n"
              data = ''
            when /Remove anonymous users/.test data
              stream.write "#{if remove_anonymous then 'y' else 'n'}\n"
              data = ''
            when /Disallow root login remotely/.test data
              stream.write "#{if disallow_remote_root_login then 'y' else 'n'}\n"
              data = ''
            when /Remove test database and access to it/.test data
              stream.write "#{if remove_test_db then 'y' else 'n'}\n"
              data = ''
            when /Reload privilege tables now/.test data
              stream.write "#{if reload_privileges then 'y' else 'n'}\n"
              data = ''
            when /All done/.test data
              stream.end 'exit\n' unless exit
              exit = true
            when /ERROR/.test data
              return if data.toString().indexOf('ERROR 1008 (HY000) at line 1: Can\'t drop database \'test\'') isnt -1
              error = new Error data
              stream.end 'exit\n' unless exit
              exit = true
        stream.on 'exit', ->
          return next error if error
          if disallow_remote_root_login then return next null, modified
          # Note, "WITH GRANT OPTION" is required for root
          query = (query) -> "mysql -uroot -p#{password} -s -e \"#{query}\""
          sql =
          ctx.execute
            cmd: query """
            USE mysql;
            GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '#{password}' WITH GRANT OPTION;
            FLUSH PRIVILEGES;
            """
            not_if_exec: """
            password=`#{query "SELECT PASSWORD('#{password}');"}`
            #{query "SHOW GRANTS FOR root;"} | grep $password
            """
          , next
