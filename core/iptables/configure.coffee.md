
    module.exports = handler: ->
      @config.iptables ?= {}
      @config.iptables.action ?= 'start'
      # Service supports chkconfig, but is not referenced in any runlevel
      @config.iptables.startup ?= ''
      @config.iptables.rules ?= []
      @config.iptables.log ?= false
      @config.iptables.log = @config.iptables.log is 'true' if typeof @config.iptables.log is 'string'
      @config.iptables.log_prefix ?= '@config.iptables-Dropped: '
      @config.iptables.log_level ?= 4
      @config.iptables.log_rules ?= [
        { chain: 'INPUT', command: '-A', jump: 'LOGGING' }
        { chain: 'LOGGING', command: '-A', '--limit': '2/min', jump: 'LOG', 'log-prefix': @config.iptables.log_prefix, 'log-level': @config.iptables.log_level }
        { chain: 'LOGGING', command: '-A', jump: 'DROP' }
      ]
