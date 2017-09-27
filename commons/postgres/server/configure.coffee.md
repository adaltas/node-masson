
# PostgreSQL Server Configure

    module.exports = ->
      service = migration.call @, service, 'masson/commons/postgres/server', ['postgresql', 'server'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        docker: key: ['docker']
      options = @config.postgres.server = service.options

## Configuration

      options.password ?= 'root'
      options.user ?= 'root'
      options.port ?= '5432'
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Docker

      options.image_dir ?= "/tmp_#{Date.now()}"
      options.version ?= '9.5'
      options.container_name ?= 'postgres_server'

## Wait

      options.wait_tcp = {}
      options.wait_tcp.fqdn = service.node.fqdn
      options.wait_tcp.port = options.port
      
