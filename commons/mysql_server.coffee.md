---
title: 
layout: module
---

# Mysql Server

    each = require 'each'
    escape = (text) -> text.replace(/[\\"]/g, "\\$&")
    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/iptables'
    module.exports.push 'masson/commons/mysql_client' # Install the mysql driver

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
{ "mysql_server": {
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
} } } }
```

    module.exports.push module.exports.configure = (ctx) ->
      require('../core/iptables').configure ctx
      ctx.config.mysql_server ?= {}
      # User SQL
      ctx.config.mysql_server.sql_on_install ?= []
      ctx.config.mysql_server.sql_on_install = [ctx.config.mysql_server.sql_on_install] if typeof ctx.config.mysql_server.sql_on_install is 'string'
      # Secure Installation
      ctx.config.mysql_server.current_password ?= ''
      ctx.config.mysql_server.password ?= ''
      ctx.config.mysql_server.remove_anonymous ?= true
      ctx.config.mysql_server.disallow_remote_root_login ?= false
      ctx.config.mysql_server.remove_test_db ?= true
      ctx.config.mysql_server.reload_privileges ?= true
      # Service Configuration
      ctx.config.mysql_server.my_cnf ?= {}
      ctx.config.mysql_server.my_cnf['mysqld'] ?= {}
      ctx.config.mysql_server.my_cnf['mysqld']['tmpdir'] ?= '/tmp/mysql'

## IPTables

| Service    | Port | Proto | Parameter |
|------------|------|-------|-----------|
| MySQL      | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to 
"start" (default value).

    module.exports.push name: 'HDP ZooKeeper # IPTables', callback: (ctx, next) ->
      ctx.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3306, protocol: 'tcp', state: 'NEW', comment: "MySQL" }
        ]
        if: ctx.config.iptables.action is 'start'
      , (err, configured) ->
        next err, if configured then ctx.OK else ctx.PASS

## Package

Install the Mysql database server. Secure the temporary directory.

    module.exports.push name: 'Mysql Server # Package', timeout: -1, callback: (ctx, next) ->
      {my_cnf} = ctx.config.mysql_server
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
          uid: 'mysql'
          gid: 'mysql'
          mode: '0744'
        , (err, created) ->
          return next err if err
          modified = true if created
          ctx.ini
            destination: '/etc/my.cnf'
            content: my_cnf
            merge: true
            backup: true
          , (err, updated) ->
            return next err if err
            modified = true if updated
            do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_install()

    module.exports.push name: 'Mysql Server # Start', callback: (ctx, next) ->
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
          ctx.service
            name: 'mysql-server'
            srv_name: 'mysqld'
            action: 'start'
          , (err, started) ->
            return next err if err
            modified = true if started
            do_end()
      do_end = ->
        next null, if modified then ctx.OK else ctx.PASS
      do_start()

    module.exports.push name: 'Mysql Server # Populate', callback: (ctx, next) ->
      {sql_on_install} = ctx.config.mysql_server
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
        next err, ctx.PASS

## Secure Installation

/usr/bin/mysql_secure_installation (run as root after install).
Enter current password for root (enter for none):
Set root password? [Y/n] y
>> big123
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] n
Remove test database and access to it? [Y/n] y

    module.exports.push name: 'Mysql Server # Secure', callback: (ctx, next) ->
      {current_password, password, remove_anonymous, disallow_remote_root_login, remove_test_db, reload_privileges} = ctx.config.mysql_server
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
          if disallow_remote_root_login then return next null, if modified then ctx.OK else ctx.PASS
          # Note, "WITH GRANT OPTION" is required for root
          sql = """
          USE mysql;
          GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY "#{password}" WITH GRANT OPTION;
          FLUSH PRIVILEGES;
          """
          ctx.execute
            cmd: "mysql -uroot -p#{password} -e \"#{escape sql}\""
          , (err, executed) ->
            next err, if modified then ctx.OK else ctx.PASS

  


