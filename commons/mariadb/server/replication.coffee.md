
# MariaDB Server Replication

Enable the replication.
Follow [instructions](https://www.digitalocean.com/community/tutorials/how-to-set-up-master-slave-replication-in-mysql).

Note: Ryba does not do any action if replication has already be enabled once for
consistency reasons.

    module.exports = header: 'MariaDB Server Replication', handler: ({options}) ->
      return unless options.ha_enabled
      
      remote_master =
        database: null
        admin_username: options.repl_master.admin_username
        admin_password: options.repl_master.admin_password
        engine: 'mysql'
        host: options.repl_master.fqdn
        silent: false
      props =
        database: null
        admin_username: options.admin_username
        admin_password: options.admin_password
        engine: 'mysql'
        host: options.fqdn
        silent: false

## Wait
Wait for master remote login.

      @wait.execute
        header: 'Wait Root remote login'
        cmd: db.cmd remote_master, "show databases"

## Grant Privileges
Grant privileges on the remote master server to the user used for replication.

      @call header: 'Replication Activation', handler: ->
        master_pos = null
        master_file = null
        @system.execute
          header: 'Slave Privileges'
          cmd: db.cmd remote_master, """
            GRANT REPLICATION SLAVE ON *.* TO '#{options.repl_master.username}'@'%' IDENTIFIED BY '#{options.repl_master.password}';
            FLUSH PRIVILEGES;
          """
          unless_exec: "#{db.cmd remote_master, 'select User from mysql.user ;'} | grep '#{options.repl_master.username}'"

## Setup Replication
Gather the target master informations, then start the slave replication.

        @call
          header: 'Slave Setup'
          unless_exec: "#{db.cmd props, 'show slave status \\G'} | grep 'Master_Host' | grep '#{options.repl_master.fqdn}'"
          handler: ->
            @system.execute
              header: 'Master Infos'
              cmd: db.cmd remote_master, "show master status \\G"
            , (err, data) ->
              throw err if err
              lines = string.lines data.stdout
              for line in lines
                parts = line.trim().split(':')
                master_file = parts[1].trim() if parts[0] is 'File'
                master_pos = parts[1].trim() if parts[0] is 'Position'
            @call ->
              @system.execute
                cmd: db.cmd props, """
                  STOP SLAVE ;
                  RESET SLAVE ;
                  CHANGE MASTER TO \
                  MASTER_HOST = '#{options.repl_master.fqdn}', \
                  MASTER_USER = '#{options.repl_master.username}', \
                  MASTER_PASSWORD = '#{options.repl_master.password}',
                  MASTER_LOG_FILE='#{master_file}', \
                  MASTER_LOG_POS=#{master_pos} ;
                  START SLAVE ;
                """

## Dependencies

    db = require '@nikitajs/core/lib/misc/db'
    string = require '@nikitajs/core/lib/misc/string'
