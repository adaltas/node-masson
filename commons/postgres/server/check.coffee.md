
# PostgreSQL Server Check

    module.exports =  header: 'PostgreSQL Server Check', label_true: 'CHECKED', handler: ->
      @connection.wait
        host: @config.host
        port: 5432
