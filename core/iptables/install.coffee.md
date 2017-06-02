
## Iptables Install

## Package

The package "iptables" is installed.

    module.exports = header: 'Iptables Install', handler: (options) ->
      {action, startup} = @config.iptables
      
      @service
        name: 'iptables'
        startup: startup
        action: action
      @service
        if_os: name: ['redhat','centos'], version: '7'
        header: 'Iptable Service'
        name: 'iptables-services'

## Log

Redirect input logs in "/var/log/messages".

      @call
        header: 'Log'
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
        if: @config.iptables.action is 'start'
        rules: @config.iptables.rules
