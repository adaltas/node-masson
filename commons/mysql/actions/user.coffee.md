
# MySQL Server Install

    export default ->
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
        [ $exist -gt 0 ] && exit 3
        mysql_exec <<SQL
        GRANT ALL PRIVILEGES \
         ON *.* TO 'root'@'#{mysql.server.root_host}' \
         IDENTIFIED BY '#{mysql.server.password}'; \
        UPDATE mysql.user \
         SET Grant_priv='Y', Super_priv='Y' \
         WHERE User='root' and Host='#{mysql.server.root_host}';
        FLUSH PRIVILEGES;
        SQL
        """
        code_skipped: 3

## Dependencies

    misc = require '@nikitajs/core/lib/misc'
    db = require '@nikitajs/core/lib/misc/db'
    path = require 'path'
