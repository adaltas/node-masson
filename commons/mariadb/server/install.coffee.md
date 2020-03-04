
# MariaDB Server Install

    module.exports = header: 'MariaDB Server Install', handler: ({options}) ->

## IPTables

| Service         | Port | Proto | Parameter |
|-----------------|------|-------|-----------|
| MariaDB         | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.my_cnf['mysqld']['port'], protocol: 'tcp', state: 'NEW', comment: "MariaDB" }
        ]
        if: options.iptables

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
        @system.group options.group
        @system.user options.user

## Package

Install the MariaDB database server. Secure the temporary directory. Install MariaDB
Package on Centos/Redhat 7 OS.

      @call header: 'Package', ->
        @tools.repo
          if: options.repo?.source?
          header: 'Repository'
          source: options.repo.source
          target: options.repo.target
          replace: options.repo.replace
          update: true
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service
            name: options.name
            chk_name: options.chk_name
            startup: true
          @system.tmpfs
            mount: "#{path.dirname options.my_cnf['mysqld']['pid-file']}"
            name: 'mariadb'
            perm: '0750'
            uid: options.user.name
            gid: options.group.name
        @service
          if_os: name: ['redhat','centos'], version: '6'
          name: 'mysql-server'
          chk_name: 'mariadb'
          startup: true

## Layout

Create the directories, needed by the database.

      @system.mkdir
        target: '/tmp/mysql'
        uid: options.user.name
        gid: options.group.name
        mode: 0o0774
      @system.mkdir
        header: 'Journal log dir'
        target: options.journal_log_dir
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Bin log dir'
        target: options.my_cnf['mysqld']['log-bin']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Data dir'
        target: options.my_cnf['mysqld']['datadir']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Priv file'
        target: options.my_cnf['mysqld']['secure-file-priv']
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Log dir'
        target: "#{path.dirname options.my_cnf['mysqld']['log-error']}"
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Run dir'
        target: "#{path.dirname options.my_cnf['mysqld']['pid-file']}"
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        header: 'Socket Dir'
        target: "#{path.dirname options.my_cnf['mysqld']['socket']}"
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750
      @system.mkdir
        if: options.ha_enabled
        header: 'Replication dir'
        target: options.replication_dir
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750

## Configuration

Generates the `my.cnf` file, read be MariaDB, and restart the service if it 
is running.

      @call header: 'Configuration', handler: ->
        @file.types.my_cnf
          content: options.my_cnf
          merge: false
          backup: true
        @service.status
          name: options.srv_name
          unless: -> @status -1
        @service.restart
          header: 'Restart'
          name: options.srv_name
          if: -> @status(-2) and @status(-1)
      # TODO: wait for error in nikita
      # @call 
      #   if: -> @error -1
      #   handler: ->
      #     @system.remove
      #       target: "/var/lib/mysql/options.sock"
      #     , (err, removed) ->
      #       throw err if err
      #       throw Error 'Failed to install mysqld' unless removed
      #     @service.start
      #       name: 'mysqld'
      for sql, i in options.sql_on_install
        @system.execute
          header: "Populate #{i}"
          cmd: "mysql -uroot -e \"#{escape sql}\""
          code_skipped: 1

## TLS

      @call header: 'TLS', if: options.ssl.enabled, handler: ->
        (if options.ssl.cacert.local then @file.download else @system.copy)
          source: options.ssl.cacert.source
          target: "#{options.my_cnf['mysqld']['ssl-ca']}"
          uid: options.user.name
          gid: options.group.name
        (if options.ssl.cert.local then @file.download else @system.copy)
          source: options.ssl.cert.source
          target: "#{options.my_cnf['mysqld']['ssl-cert']}"
          uid: options.user.name
          gid: options.group.name
        (if options.ssl.key.local then @file.download else @system.copy)
          source: options.ssl.key.source
          target: "#{options.my_cnf['mysqld']['ssl-key']}"
          uid: options.user.name
          gid: options.group.name

      @call header: 'Init data directory', handler: ->
        @system.execute
          cmd: "mysql_install_db --user=#{options.my_cnf['mysqld']['user']}  --datadir=#{options.my_cnf['mysqld']['datadir']}"
          unless_exists: "#{options.my_cnf['mysqld']['datadir']}/mysql/db.frm"

## Secure Installation

`/usr/bin/mysql_secure_installation` (run as root after install).
Enter current password for root (enter for none):
Set root password? [Y/n] y
>> big123
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] n
Remove test database and access to it? [Y/n] y

Note: Due to a [bug](http://bugs.options.com/bug.php?id=46842), `/usr/bin/mysql_secure_installation`
can only be used when MariaDB runs on the default socket (`/var/lib/mysql/options.scoket`).
To setup secure installation, Ryba does start MariaDB  on the default socket 
when admin user has configured it elsewhere, then it restarts the database server 
with the chosen params. Other action could be used to change the root password, but
`/usr/bin/mysql_secure_installation` program is to the one to be used for production
envrionment.
The bug is fixed after version 5.7 of MariaDB.

      @call header: 'Secure Install', ->
        test_password = true
        modified = false
        safe_start = true
        database =
          database: null
          admin_username: options.admin_username
          admin_password: options.admin_password
          engine: 'mysql'
          host: 'localhost'
        # @system.execute
        #   cmd: 'mysql -V'
        #   shy: true
        #   trim: true
        # , (err, status, stdout, stderr) ->
        #   throw err if err
        #   # Not documented and not working
        #   # match = /([0-9].){3}/.exec stdout
        #   # version = match[0].split('.')[1] if match
        #   # safe_start = not (version >= 7) or ((version <= 7) and options.my_cnf['mysqld']['socket'] is '/var/lib/mysql/mysql.sock')
        #   # A proposal could be
        #   # match = /([0-9\.]+)-MariaDB/.exec stdout
        #   # [major, minor] = match[1].split('.') if match
        #   # But I dont even know what the old code was trying to achieve
        #   safe_start = false
        @call
          unless_exec: "#{db.cmd database, 'show databases'}"
        , ->
          @call
            header: 'Configure Socket'
            if: -> safe_start
          , ->
            @service.stop
              name: options.srv_name
            @system.execute
              cmd: "mysqld_safe --socket=/var/lib/mysql/mysql.sock > /dev/null 2>&1 &"
            @wait.exist
              target: options.my_cnf['mysqld_safe']['pid-file']
            @wait.exist
              target: '/var/lib/mysql/mysql.sock'
          @call
            header: 'Change Password'
          , (_, callback) ->
            ssh = @ssh options.ssh
            ssh.shell (err, stream) =>
              stream.write "if #{options.sudo and 'sudo'} /usr/bin/mysql_secure_installation ;then exit 0; else exit 1;fi\n"
              data = ''
              error = exit = null
              stream.on 'data', (data, extended) =>
                # todo: not working anymore after implementing log object in nikita
                # @log message = data, type: ''
                # @log[if extended is 'stderr' then 'err' else 'out']?.write data
                # for now @log to see nonetheless what is executed
                data = data.toString()
                switch
                  when /Enter current password for root/.test data
                    @log data
                    stream.write "#{if test_password then options.admin_password else options.current_password}\n"
                    data = ''
                  when /ERROR 1045/.test(data) and test_password
                    @log data
                    test_password = false
                    modified = true
                    data = ''
                  when /Change the root password/.test data
                    @log data
                    stream.write "y\n"
                    data = ''
                  when /Set root password/.test data
                    @log data
                    stream.write "y\n"
                    data = ''
                  when /New password/.test(data) or /Re-enter new password/.test(data)
                    @log data
                    stream.write "#{options.admin_password}\n"
                    data = ''
                  when /Remove anonymous users/.test data
                    @log data
                    stream.write "#{if options.remove_anonymous then 'y' else 'n'}\n"
                    data = ''
                  when /Disallow root login remotely/.test data
                    @log data
                    stream.write "#{if options.disallow_remote_root_login then 'y' else 'n'}\n"
                    data = ''
                  when /Remove test database and access to it/.test data
                    @log data
                    stream.write "#{if options.remove_test_db then 'y' else 'n'}\n"
                    data = ''
                  when /Reload privilege tables now/.test data
                    @log data
                    stream.write "#{if options.reload_privileges then 'y' else 'n'}\n"
                    data = ''
                  when /All done/.test data
                    @log data
                    stream.end 'exit\n' unless exit
                    exit = true
                  when /ERROR/.test data
                    @log data
                    return if data.toString().indexOf('ERROR 1008 (HY000) at line 1: Can\'t drop database \'test\'') isnt -1
                    error = new Error data.toString()
                    if data.toString().indexOf('ERROR 2002 (HY000)') isnt -1
                      error = new Error 'MariaDB Server Not started'
                    stream.end 'exit\n' unless exit
                    exit = true
              stream.on 'close', ->
                callback error
          @call
            if: -> safe_start
          , ->
            @system.execute
              cmd: """
              pid=$(cat #{options.my_cnf['mysqld']['pid-file']})
              kill $pid
              """
            @wait.execute
              cmd: "if [ -f \"#{options.my_cnf['mysqld']['pid-file']}\" ]; then exit 1; else exit 0 ; fi"
            @service.start
              name: options.srv_name
        @call
          header: 'Allow Root Remote Login'
          unless: options.disallow_remote_root_login
        , ->
          # Note, "WITH GRANT OPTION" is required for root
          query = (query) -> "mysql -uroot -p#{options.admin_password} -s -e \"#{query}\""
          @service.start
            name: options.srv_name
          @system.execute
            cmd: query """
            USE mysql;
            GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '#{options.admin_password}' WITH GRANT OPTION;
            FLUSH PRIVILEGES;
            """
            unless_exec: """
            password=`#{query "SELECT PASSWORD('#{options.admin_password}');"}`
            #{query "SHOW GRANTS FOR root;"} | grep $password
            """
      
    escape = (text) -> text.replace(/[\\"]/g, "\\$&")

## Dependencies

    misc = require '@nikitajs/core/lib/misc'
    db = require '@nikitajs/core/lib/misc/db'
    path = require 'path'
