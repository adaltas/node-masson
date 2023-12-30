
# Iptables Install

    export default header: 'Iptables Install', handler: ({options}) ->

## Package

Install the "iptables" package and "iptables-services" on RH7.

      @service
        name: 'iptables'
        startup: options.startup
        action: options.action
      @service
        if_os: name: ['redhat','centos'], version: '7'
        header: 'Iptable Service'
        name: 'iptables-services'

## Log

Redirect input logs in "/var/log/messages".

      @call
        header: 'Log'
        unless: -> options.action isnt 'start' or options.redirect_log is false
      , ->
        @tools.iptables
          rules: options.log_rules
        @service
          srv_name: 'restart'
          if: -> @status -1

## Rules

Add user defined rules to IPTables.

      @tools.iptables
        header: 'Rules'
        if: options.action is 'start'
        rules: options.rules
