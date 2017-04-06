
## Iptables Install

## Package

The package "iptables" is installed.

    module.exports = header: 'Iptables Install', handler: (options) ->
      {action, startup} = @config.iptables
      
      @service
        timeout: -1
        name: 'iptables'
        startup: startup
        action: action
      @system.discover (err, status, os) ->
        @service
          if: -> (os.type in ['redhat','centos']) and os.release[0] is '7'
          header: 'Iptable Service'
          name: 'iptables-services'

## Log

Redirect input logs in "/var/log/messages".

      @call
        header: 'Log'
        timeout: -1
        unless: -> @config.iptables.action isnt 'start' or @config.iptables.log is false
        handler: ->
          @tools.iptables
            rules: @config.iptables.log_rules
          @service
            srv_name: 'restart'
            if: -> @status -1

## Rules

Add user defined rules to IPTables.

      @tools.iptables
        header: 'Rules'
        timeout: -1
        if: @config.iptables.action is 'start'
        rules: @config.iptables.rules
