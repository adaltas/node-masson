
# PostgreSQL Server Check

    module.exports =  header: 'PostgreSQL Server Check', label_true: 'CHECKED', handler: ->
      @wait_connect
        host: @config.host
        port: 5432
