
# Mysql

Install the MySQL command-line tool.

    module.exports =
      commands:
        'install': handler: (options) ->

## Package

Install the Mysql client.

          @service.install
            name: 'mysql'
            code_skipped: 1
          @call
            if: -> (options.store['mecano:system:type'] in ['redhat','centos'])
            handler: ->
              @service
                if: -> (options.store['mecano:system:release'][0] is '7')
                name: 'mariadb'
              @service
                if: -> (options.store['mecano:system:release'][0] is '6')
                name: 'mysql'

## Connector

Install the Mysql JDBC driver.

          @service
            header: 'Connector'
            name: 'mysql-connector-java'
