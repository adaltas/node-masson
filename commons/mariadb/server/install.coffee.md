
# MySQL Server Install

    module.exports = header: 'MySQL Server Install', handler: ->
      {iptables, mysql} = @config
      {ssl} = @config.ryba
      service_name = 'mysqld'

## IPTables

| Service           | Port | Proto | Parameter |
|-------------------|------|-------|-----------|
| MySQL/MariaDB     | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: mysql.server.my_cnf['mysqld']['port'], protocol: 'tcp', state: 'NEW', comment: "MySQL" }
        ]
        if: iptables.action is 'start'

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

      @call header: 'Package', timeout: -1, handler: (options) ->
        @service.install
          name: 'mysql-server'
          code_skipped: 1
        @system.discover (err, status, os) ->
          @call 
            shy: true
            if: -> (os.type in ['redhat','centos'])
            handler: ->
              service_name = switch os.release[0]
                when '7' then'mariadb'
                else 'mysqld'
          @call
            if: -> (os.type in ['redhat','centos'])
            handler: ->
              @call
                if: -> (os.release[0] is '7')
                handler: ->
                  @service
                    name: 'mariadb-server'
                    chk_name: service_name
                    startup: true
                  @system.tmpfs
                    mount: "#{path.dirname mysql.server.my_cnf['mysqld']['pid-file']}"
                    name: 'mariadb'
                    perm: '0750'
                    uid: mysql.server.user.name
                    gid: mysql.server.group.name
              @service
                if: -> (os.release[0] is '6')
                name: 'mysql-server'
                chk_name: service_name
                startup: true

## Layout

Create the directories, needed by the database.

      @system.mkdir
        target: '/tmp/mysql'
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0774
      @system.mkdir
        header: 'Journal log dir'
        target: mysql.journal_log_dir
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Bin log dir'
        target: mysql.server.my_cnf['mysqld']['log-bin']
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Data dir'
        target: mysql.server.my_cnf['mysqld']['datadir']
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Priv file'
        target: mysql.server.my_cnf['mysqld']['secure-file-priv']
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Log dir'
        target: "#{path.dirname mysql.server.my_cnf['mysqld']['log-error']}"
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Run dir'
        target: "#{path.dirname mysql.server.my_cnf['mysqld']['pid-file']}"
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Socket Dir'
        target: "#{path.dirname mysql.server.my_cnf['mysqld']['socket']}"
        uid: mysql.server.user.name
        gid: mysql.server.group.name
        mode: 0o0750

## Configuration

Generates the `my.cnf` file, read be MySQL/MariaDB, and restart the service if it 
is running.

      @call header: 'Configuration', handler: ->
        @file.ini
          target: '/etc/my.cnf'
          content: mysql.server.my_cnf
          stringify: misc.ini.stringify_single_key
          merge: false
          backup: true
        @service.status
          name: service_name
          unless: -> @status -1
        @service.restart
          header: 'Restart'
          name: service_name
          if: -> @status(-2) and @status(-1)
      # TODO: wait for error in nikita
      # @call 
      #   if: -> @error -1
      #   handler: ->
      #     @system.remove
      #       target: "/var/lib/mysql/mysql.sock"
      #     , (err, removed) ->
      #       throw err if err
      #       throw Error 'Failed to install mysqld' unless removed
      #     @service.start
      #       name: 'mysqld'
      for sql, i in mysql.server.sql_on_install
        @system.execute
          header: "Populate #{i}"
          cmd: "mysql -uroot -e \"#{escape sql}\""
          code_skipped: 1

## SSL

      @call header: 'SSL', handler: ->
        @file.download
          source: ssl.cert
          target: "#{mysql.server.my_cnf['mysqld']['ssl-cert']}"
          uid: mysql.server.user.name
          gid: mysql.server.group.name
        @file.download
          source: ssl.key
          target: "#{mysql.server.my_cnf['mysqld']['ssl-key']}"
          uid: mysql.server.user.name
          gid: mysql.server.group.name
        @file.download
          source: ssl.cacert
          target: "#{mysql.server.my_cnf['mysqld']['ssl-ca']}"
          uid: mysql.server.user.name
          gid: mysql.server.group.name
      
      @call header: 'Init data directory', handler: ->
        @system.execute
          cmd: "mysql_install_db --user=#{mysql.server.my_cnf['mysqld']['user']}  --datadir=#{mysql.server.my_cnf['mysqld']['datadir']}"
          unless_exists: "#{mysql.server.my_cnf['mysqld']['datadir']}/mysql"

## Secure Installation

`/usr/bin/mysql_secure_installation` (run as root after install).
Enter current password for root (enter for none):
Set root password? [Y/n] y
>> big123
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] n
Remove test database and access to it? [Y/n] y

Note: Due to a [bug](http://bugs.mysql.com/bug.php?id=46842), `/usr/bin/mysql_secure_installation`
can only be used when MySQL/MariaDB runs on the default socket (`/var/lib/mysql/mysql.scoket`).
To setup secure installation, Ryba does start MySQL/MariaDB  on the default socket 
when admin user has configured it elsewhere, then it restarts the database server 
with the chosen params. Other action could be used to change the root password, but
`/usr/bin/mysql_secure_installation` program is to the one to be used for production
envrionment.
The bug is fixed after version 5.7 of MySQL/MariaDB.

      @call 
        header: 'Secure Installation'
        handler: ->
          {current_password, password, remove_anonymous, disallow_remote_root_login, remove_test_db, reload_privileges} = mysql.server
          test_password = true
          modified = false
          version = null
          safe_start = false
          database =
            database: null
            admin_username: 'root'
            admin_password: password
            engine: 'mysql'
            host: 'localhost'
          @system.execute
            cmd: 'mysql -V'
            shy: true
          , (err, status, stdout, stderr) ->
            throw err if err
            match = /([0-9].){3}/.exec stdout
            version = match[0].split('.')[1] if match
            safe_start = not (version >= 7) or ((version <= 7) and mysql.server.my_cnf['mysqld']['socket'] is '/var/lib/mysql/mysql.sock')
          @call 
            header: 'Secure MySQL'
            unless_exec: "#{db.cmd database, 'show databases'}"
            handler: ->
              @call 
                if: -> safe_start
                header: 'Configure Socket'
                handler: ->
                  @service.stop
                    name: service_name
                  @system.execute
                    cmd: "mysqld_safe --socket=/var/lib/mysql/mysql.sock > /dev/null 2>&1 &"
                  @wait_exist
                    target: mysql.server.my_cnf['mysqld_safe']['pid-file']
                  @wait_exist
                    target: '/var/lib/mysql/mysql.sock'
              @call
                header: 'Change Password'
                handler: (options, callback) ->
                  options.ssh.shell (err, stream) =>
                    stream.write 'if /usr/bin/mysql_secure_installation ;then exit 0; else exit 1;fi\n'
                    data = ''
                    error = exit = null
                    exited = false
                    stream.on 'data', (data, extended) =>
                      # todo: not working anymore after implementing log object in nikita
                      # options.log message = data, type: ''
                      # options.log[if extended is 'stderr' then 'err' else 'out']?.write data
                      # for now options.log to see nonetheless what is executed
                      data = data.toString()
                      switch
                        when /Enter current password for root/.test data
                          options.log data
                          stream.write "#{if test_password then password else current_password}\n"
                          data = ''
                        when /ERROR 1045/.test(data) and test_password
                          options.log data
                          test_password = false
                          modified = true
                          data = ''
                        when /Change the root password/.test data
                          options.log data
                          stream.write "y\n"
                          data = ''
                        when /Set root password/.test data
                          options.log data
                          stream.write "y\n"
                          data = ''
                        when /New password/.test(data) or /Re-enter new password/.test(data)
                          options.log data
                          stream.write "#{password}\n"
                          data = ''
                        when /Remove anonymous users/.test data
                          options.log data
                          stream.write "#{if remove_anonymous then 'y' else 'n'}\n"
                          data = ''
                        when /Disallow root login remotely/.test data
                          options.log data
                          stream.write "#{if disallow_remote_root_login then 'y' else 'n'}\n"
                          data = ''
                        when /Remove test database and access to it/.test data
                          options.log data
                          stream.write "#{if remove_test_db then 'y' else 'n'}\n"
                          data = ''
                        when /Reload privilege tables now/.test data
                          options.log data
                          stream.write "#{if reload_privileges then 'y' else 'n'}\n"
                          data = ''
                        when /All done/.test data
                          options.log data
                          stream.end 'exit\n' unless exit
                          exit = true
                        when /ERROR/.test data
                          options.log data
                          return if data.toString().indexOf('ERROR 1008 (HY000) at line 1: Can\'t drop database \'test\'') isnt -1
                          error = new Error data.toString()
                          if data.toString().indexOf('ERROR 2002 (HY000)') isnt -1
                            error = new Error 'MySQL Server Not started'
                          exited = true
                          return callback error, modified
                    stream.on 'exit', =>
                      if not exited
                        return callback error if error
                        @call
                          if: -> safe_start
                          handler: ->
                            @system.execute
                              cmd: """
                                  pid=$(cat #{mysql.server.my_cnf['mysqld']['pid-file']})
                                  kill $pid
                                """
                            @wait.execute
                              cmd: "if [ -f \"#{mysql.server.my_cnf['mysqld']['pid-file']}\" ]; then exit 1; else exit 0 ; fi"
                            @service.start
                              name: service_name
                        @then callback
          @call
            header: 'Allow Root Remote Login'
            unless: disallow_remote_root_login
            handler: ->
              # Note, "WITH GRANT OPTION" is required for root
              query = (query) -> "mysql -uroot -p#{password} -s -e \"#{query}\""
              sql =
              @service.start service_name
              @system.execute
                cmd: query """
                USE mysql;
                GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '#{password}' WITH GRANT OPTION;
                FLUSH PRIVILEGES;
                """
                unless_exec: """
                password=`#{query "SELECT PASSWORD('#{password}');"}`
                #{query "SHOW GRANTS FOR root;"} | grep $password
                """

    escape = (text) -> text.replace(/[\\"]/g, "\\$&")

## Dependencies

    misc = require 'nikita/lib/misc'
    db = require 'nikita/lib/misc/db'
    path = require 'path'