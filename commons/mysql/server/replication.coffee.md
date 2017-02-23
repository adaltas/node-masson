
# Mysql Server Replication
Enable the replication.
Follow [instructions](https://www.digitalocean.com/community/tutorials/how-to-set-up-master-slave-replication-in-mysql).

Note: Ryba does not do any action if replication has already be enabled once for
consistency reasons.

    module.exports = header: 'Mysql Server Replication', handler: ->
      return unless @config.mysql.ha_enabled
      {repl_master} = @config.mysql.server
      [master_ctx] = @contexts('masson/commons/mysql/server').filter (ctx) -> ctx.config.host is repl_master.host
      remote_master =
        database: null
        admin_username: 'root'
        admin_password: master_ctx.config.mysql.server.password
        engine: 'mysql'
        host: master_ctx.config.host
        silent: false
      props =
        database: null
        admin_username: 'root'
        admin_password: @config.mysql.server.password
        engine: 'mysql'
        host: @config.host
        silent: false

## Wait
Wait for master remote login.

      @wait.execute
        header: 'Wait Root remote login'
        cmd: db.cmd remote_master, "show databases"

## Layout

      @system.mkdir
        header: 'Replication dir'
        target: @config.mysql.replication_dir
        uid: @config.mysql.server.user.name
        gid: @config.mysql.server.group.name
        mode: 0o0750

## Grant Privileges
Grant privileges on the remote master server to the user used for replication.

      @call header: 'Replication Activation', handler: ->
        master_pos = null
        master_file = null
        @system.execute
          header: 'Slave Privileges'
          cmd: db.cmd remote_master, """
            GRANT REPLICATION SLAVE ON *.* TO '#{repl_master.user}'@'%' IDENTIFIED BY '#{repl_master.pwd}';
            FLUSH PRIVILEGES;
          """
          unless_exec: "#{db.cmd remote_master, 'select User from mysql.user ;'} | grep '#{repl_master.user}'"

## Setup Replication
Gather the target master informations, then start the slave replication.

        
        @call 
          header: 'Slave Setup'
          unless_exec: "#{db.cmd props, 'show slave status \\G'} | grep 'Master_Host' | grep '#{repl_master.host}'"
          handler: ->
            @system.execute
              header: 'Master Infos'
              cmd: db.cmd remote_master, "show master status \\G"
            , (err, status, stdout, stderr) ->
              throw err if err
              lines = string.lines stdout
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
                  MASTER_HOST = '#{repl_master.host}', \
                  MASTER_USER = '#{repl_master.user}', \
                  MASTER_PASSWORD = '#{repl_master.pwd}',
                  MASTER_LOG_FILE='#{master_file}', \
                  MASTER_LOG_POS=#{master_pos} ;
                  START SLAVE ;
                """
              

## Dependencies

    db = require 'mecano/lib/misc/db'
    string = require 'mecano/lib/misc/string'
