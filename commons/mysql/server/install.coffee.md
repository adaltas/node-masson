
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
          if_exec: 'yum info mysql-community-release'
        @system.tmpfs
          header: 'TempFS pid'
          if_os: name: ['centos', 'redhat', 'oracle'], version: '7'
          mount: "#{path.dirname mysql.server.my_cnf['mysqld']['pid-file']}"
          name: 'mysqld'
          perm: '0750'
          uid: mysql.server.user.name
          gid: mysql.server.group.name
        @service
          header: 'Install'
          name: 'mysql-community-server'
          if_exec: 'yum info mysql-community-server'
          startup: true
          chk_name: 'mysqld'
          srv_name: 'mysqld'
          action: 'start'
        @service
          header: 'Install'
          name: 'mysql-server'
          if_exec: 'yum info mysql-server'
          startup: true
          chk_name: 'mysqld'
          srv_name: 'mysqld'
          action: 'start'

## Configuration
Write /etc/my.cnf configuration file.

      @file.ini
        target: '/etc/my.cnf'
        content: mysql.server.my_cnf
        stringify: misc.ini.stringify_single_key
        merge: false
        backup: true

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
          stream.on 'error', (err) ->
            callback err
          stream.on 'exit', =>
            @service.restart 'mysqld' unless err
            @then (err) -> callback err, true
      
      @system.execute
        header: 'External Root Access'
        if: mysql.server.root_host
        cmd: """
        function mysql_exec {
          read query
          mysql \
           -hlocalhost -P#{mysql.server.my_cnf['mysqld']['port']} \
           -uroot -p#{mysql.server.password} \
           -N -s -r -e \
           "$query" 2>/dev/null
        }
        exist=`mysql_exec <<SQL
        SELECT count(*) \
         FROM mysql.user \
         WHERE user = 'root' and host = '#{mysql.server.root_host}';
        SQL`
        [[ $exist -gt 0 ]] && exit 3
        mysql_exec <<SQL
        GRANT ALL PRIVILEGES \
         ON *.* TO 'root'@'#{mysql.server.root_host}' \
         IDENTIFIED BY '#{mysql.server.password}' \
         WITH GRANT OPTION;
        GRANT SUPER ON *.* TO 'root'@'#{mysql.server.root_host}';
        # UPDATE mysql.user \
        #  SET Grant_priv='Y', Super_priv='Y' \
        #  WHERE User='root' and Host='#{mysql.server.root_host}';
        FLUSH PRIVILEGES;
        SQL
        """
        code_skipped: 3

## Dependencies

    misc = require 'nikita/lib/misc'
    db = require 'nikita/lib/misc/db'
    path = require 'path'
