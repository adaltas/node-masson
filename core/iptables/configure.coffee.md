
# IPTables Configure

    module.exports = ->
      options = @config.iptables ?= {}
      options.action ?= 'start'
      # Service supports chkconfig, but is not referenced in any runlevel
      options.startup ?= ''
      options.rules ?= []
      options.log ?= false
      options.log = options.log is 'true' if typeof options.log is 'string'
      options.log_prefix ?= 'iptables-Dropped: '
      options.log_level ?= 4
      options.log_rules ?= [
        { chain: 'INPUT', command: '-A', jump: 'LOGGING' }
        { chain: 'LOGGING', command: '-A', '--limit': '2/min', jump: 'LOG', 'log-prefix': options.log_prefix, 'log-level': options.log_level }
        { chain: 'LOGGING', command: '-A', jump: 'DROP' }
      ]
