
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
          @system.discover (err, status, os) ->
            @call
              if: -> (os.type in ['redhat','centos'])
              handler: ->
                @service
                  if: -> (os.release[0] is '7')
                  name: 'mariadb'
                @service
                  if: -> (os.release[0] is '6')
                  name: 'mysql'

## Connector

Install the Mysql JDBC driver.

          @service
            header: 'Connector'
            name: 'mysql-connector-java'
