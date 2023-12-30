
# MySQL Server Install

Install MySQL Server 5.7 community based on the [official intructions]. Note,
it differs from prior versions (5.6 and less) in the way there is no longer
the "mysql_secure_installation" script and the password is stashed into the
logs.

    export default header: 'MySQL Server Install', handler: (options) ->

## IPTables

| Service           | Port | Proto | Parameter |
|-------------------|------|-------|-----------|
| MySQL             | 3306 | tcp   | -         |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.my_cnf['mysqld']['port'], protocol: 'tcp', state: 'NEW', comment: "MySQL" }
        ]
        if: options.iptables

## User & groups
By default the "mariadb-server/mysql-server" packages create the following entry:

```bash
cat /etc/passwd | egrep '^mysql:'
mysql:x:27:27:MySQL Server:/var/lib/mysql:/bin/false
```

Actions present to be able to change uid/gid:
Note: Be careful if using different name thans 'mysql:mysql'
User/group are hard coded in some of mariadb/mysql package scripts.

      @system.group 'Group', options.group
      @system.user 'User', options.user

## Repository

If running on RedHad, the package "mysql-community-server" is MySQL Server 5.7. 
On CentOS 7.3, MySQL is not available in the default repoitory and the 
repository can be downloaded by installing the "mysql57-community-release-el7" 
package. 

## Package

Install the MySQL database server. Secure the temporary directory.

      @call header: 'Package', ->
        @system.tmpfs
          header: 'TempFS pid'
          if_os: name: ['centos', 'redhat', 'oracle'], version: '7'
          mount: "#{path.dirname options.my_cnf['mysqld']['pid-file']}"
          name: 'mysqld'
          perm: '0750'
          uid: options.user.name
          gid: options.group.name
        @service
          header: 'Install'
          name: 'mysql-community-server'
          chk_name: 'mysqld'
          srv_name: 'mysqld'
          startup: true
          state: 'started'

## Configuration
Write /etc/my.cnf configuration file.

      @file.ini
        target: '/etc/my.cnf'
        content: options.my_cnf
        stringify: misc.ini.stringify_single_key
        merge: true
        backup: true

## Secure Temp Password

If this is the first run, grab the temporary password from the log.

      password = null
      @system.execute
        header: 'Temp Password'
        unless_exec: db.cmd
          engine: 'mysql'
          host: 'localhost'
          username: 'root'
          password: "#{options.password}"
        , "SHOW STATUS"
        cmd: "grep 'temporary password' /var/log/mysqld.log"
        shy: true
      , (err, status, stdout) ->
        throw err if err
        password = / ([^ ]+)$/.exec(stdout)[1].trim() if status

## Secure Root Password

Now we open a shell to change the password. Note, we can not pass the query as 
a command argumet because it can not be run interractively.

      @call
        header: 'Root Password'
        if: -> password
      , (options, callback) ->
        ssh = @ssh options.ssh
        ssh.shell (err, stream) =>
          return callback err if err
          cmd = db.cmd
            engine: 'mysql'
            host: 'localhost'
            username: 'root'
            password: password
          stream.write "#{cmd}\n"
          err = null
          called = 0
          stream.on 'data', (data, extended) =>
            data = data.toString()
            if /ERROR/.test data
              err = new Error /ERROR.*/.exec(data)[0]
              stream.write 'quit\n'
              stream.end 'exit\n'
              called = 3
            else if called is 0 and /mysql>/.test data
              stream.write "ALTER USER 'root'@'localhost' IDENTIFIED BY '#{options.password}';\n"
              called++
            else if called is 1 and /mysql>/.test data
              stream.write 'quit\n'
              called++
            else if called is 2
              stream.end 'exit\n'
              called++
          stream.on 'exit', ->
            callback err, true

      @system.execute
        header: 'External Root Access'
        if: options.root_host
        cmd: """
        function mysql_exec {
          read query
          mysql \
           -hlocalhost -P#{options.my_cnf['mysqld']['port']} \
           -uroot -p#{options.password} \
           -N -s -r -e \
           "$query" 2>/dev/null
        }
        exist=`mysql_exec <<SQL
        SELECT count(*) \
         FROM mysql.user \
         WHERE user = 'root' and host = '#{options.root_host}';
        SQL`
        [ $exist -gt 0 ] && exit 3
        mysql_exec <<SQL
        GRANT ALL PRIVILEGES \
         ON *.* TO 'root'@'#{options.root_host}' \
         IDENTIFIED BY '#{options.password}' \
         WITH GRANT OPTION;
        GRANT SUPER ON *.* TO 'root'@'#{options.root_host}';
        #UPDATE mysql.user \
        # SET Grant_priv='Y', Super_priv='Y' \
        # WHERE User='root' and Host='#{options.root_host}';
        FLUSH PRIVILEGES;
        SQL
        """
        code_skipped: 3

## Dependencies

    misc = require '@nikitajs/core/lib/misc'
    db = require '@nikitajs/core/lib/misc/db'
    path = require 'path'

## References

[official intructions]: https://dev.mysql.com/doc/mysql-repo-excerpt/5.7/en/linux-installation-yum-repo.html
