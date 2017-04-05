
# MySQL Server Install

    module.exports = header: 'MySQL Server Install', handler: ->
      {iptables, mysql} = @config

## IPTables

| Service           | Port | Proto | Parameter |
|-------------------|------|-------|-----------|
| MySQL             | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mysql.server.my_cnf['mysqld']['port'], protocol: 'tcp', state: 'NEW', comment: "MySQL" }
        ]
        if: @has_service('masson/core/iptables') and iptables.action is 'start'

## User & groups
By default the "mariadb-server/mysql-server" packages create the following entry:

```bash
cat /etc/passwd | grep mysql
mysql:x:27:27:MariaDB Server:/var/lib/mysql:/sbin/nologin
```
Actions present to be able to change uid/gid:
Note: Be careful if using different name thans 'mysql:mysql'
User/group are hard coded in some of mariadb/mysql package scripts.

      @call header: 'Users & Groups', handler: ->
        @system.group mysql.server.group
        @system.user mysql.server.user

## Package

Install the MySQL database server. Secure the temporary directory. Install MariaDB
Package on Centos/Redhat 7 OS.

      @call header: 'Package', ->
        @service.install
          name: 'mysql-community-release'
          unless_exec: 'yum info mysql-community-release'
        @service.install
          name: 'mysql-community-server'
          startup: true
          action: 'start'

## Secure Installation

This program enables you to improve the security of your MySQL installation in 
the following ways:

* Set a password for root accounts.
* Remove root accounts that are accessible from outside the local host.
* Remove anonymous-user accounts.
* Remove the test database (which by default can be accessed by all users, 
  even anonymous users), and privileges that permit anyone to access databases 
  with names that start with test_.

      @call
        header: 'Secure'
        if_exec: 'echo "show databases" | mysql -uroot'
      , (options, callback) ->
        options.ssh.shell (err, stream) =>
          return callback err if err
          err = null
          stream.write '/usr/bin/mysql_secure_installation\n'
          stream.on 'data', (data, extended) =>
            data = data.toString()
            switch
              when /Enter current password for root/.test data
                options.log data
                stream.write "#{mysql.server.current_password}\n"
              when /Change the root password/.test data
                options.log data
                stream.write "y\n"
              when /Set root password/.test data
                options.log data
                stream.write "y\n"
              when /New password/.test(data) or /Re-enter new password/.test(data)
                options.log data
                stream.write "#{mysql.server.password}\n"
              when /Remove anonymous users/.test data
                options.log data
                stream.write "y\n"
              when /Disallow root login remotely/.test data
                options.log data
                stream.write "y\n"
              when /Remove test database and access to it/.test data
                options.log data
                stream.write "y\n"
              when /Reload privilege tables now/.test data
                options.log data
                stream.write "y\n"
              when /All done/.test data
                options.log data
                stream.end 'exit\n'
          stream.on 'exit', =>
            @service.restart 'mysqld' unless err
            @then -> callback err, true

## Dependencies

    misc = require 'nikita/lib/misc'
    db = require 'nikita/lib/misc/db'
    path = require 'path'
