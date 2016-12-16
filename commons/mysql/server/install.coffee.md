
# Mysql Server Install

    module.exports = header: 'Mysql Server Install', handler: ->
      {iptables, mysql} = @config
    
## IPTables

| Service    | Port | Proto | Parameter |
|------------|------|-------|-----------|
| MySQL      | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 3306, protocol: 'tcp', state: 'NEW', comment: "MySQL" }
        ]
        if: iptables.action is 'start'

## Package

Install the Mysql database server. Secure the temporary directory.

      @call header: 'Package', timeout: -1, handler: ->
        @service
          name: 'mysql-server'
          chk_name: 'mysqld'
          startup: '235'
        @mkdir
          target: '/tmp/mysql'
          uid: mysql.server.user.name
          gid: mysql.server.group.name
          mode: 0o0744
        @file.ini
          target: '/etc/my.cnf'
          content: mysql.server.my_cnf
          merge: true
          backup: true

      @service.start
        header: 'Start'
        name: 'mysqld'
        relax: true
      # TODO: wait for error in mecano
      # @call 
      #   if: -> @error -1
      #   handler: ->
      #     @remove
      #       target: "/var/lib/mysql/mysql.sock"
      #     , (err, removed) ->
      #       throw err if err
      #       throw Error 'Failed to install mysqld' unless removed
      #     @service.start
      #       name: 'mysqld'

      for sql, i in mysql.server.sql_on_install
        @execute
          header: "Populate #{i}"
          cmd: "mysql -uroot -e \"#{escape sql}\""
          code_skipped: 1

## Secure Installation

/usr/bin/mysql_secure_installation (run as root after install).
Enter current password for root (enter for none):
Set root password? [Y/n] y
>> big123
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] n
Remove test database and access to it? [Y/n] y

      @call header: 'Secure', handler: (options, callback) ->
        {current_password, password, remove_anonymous, disallow_remote_root_login, remove_test_db, reload_privileges} = mysql.server
        test_password = true
        modified = false
        @options.ssh.shell (err, stream) =>
          stream.write '/usr/bin/mysql_secure_installation\n'
          data = ''
          error = exit = null
          stream.on 'data', (data, extended) =>
            # todo: not working anymore after implementing log object in mecano
            # options.log message = data, type: ''
            # options.log[if extended is 'stderr' then 'err' else 'out']?.write data
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
          stream.on 'exit', =>
            return callback error if error
            if disallow_remote_root_login then return callback null, modified
            # Note, "WITH GRANT OPTION" is required for root
            query = (query) -> "mysql -uroot -p#{password} -s -e \"#{query}\""
            sql =
            @execute
              cmd: query """
              USE mysql;
              GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '#{password}' WITH GRANT OPTION;
              FLUSH PRIVILEGES;
              """
              unless_exec: """
              password=`#{query "SELECT PASSWORD('#{password}');"}`
              #{query "SHOW GRANTS FOR root;"} | grep $password
              """
            .then callback

    escape = (text) -> text.replace(/[\\"]/g, "\\$&")
