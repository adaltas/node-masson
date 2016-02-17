
## Iptables Install

## Package

The package "iptables" is installed.

    module.exports = header: 'Iptables Install', handler: ->
      {action, startup} = @config.iptables
      @service
        header: 'Package'
        timeout: -1
        name: 'iptables'
        startup: startup
        action: action

## Log

Redirect input logs in "/var/log/messages".

      @call
        header: 'Log'
        timeout: -1
        unless: -> @config.iptables.action isnt 'start' or @config.iptables.log is false
        handler: ->
          @iptables
            rules: @config.iptables.log_rules
          @service
            srv_name: 'restart'
            if: -> @status -1

## Rules

Add user defined rules to IPTables.

      @iptables
        header: 'Iptables # Rules'
        timeout: -1
        if: @config.iptables.action is 'start'
        rules: @config.iptables.rules
