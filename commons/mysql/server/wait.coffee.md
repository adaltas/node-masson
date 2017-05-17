
# MySQL Server Wait

    module.exports = header: 'MySQL Server Wait', handler: ->
      # {mysql} = @config
      mysql_ctxs = @contexts 'masson/commons/mysql/server'
      options = {}
      options.wait_tcp = for mysql_ctx in mysql_ctxs
        host: mysql_ctx.config.host
        port: mysql_ctx.config.mysql.server.my_cnf['mysqld']['port']

## Wait TCP

      @connection.wait
        header: 'TCP'
        servers: options.wait_tcp
