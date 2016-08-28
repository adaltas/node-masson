
# Docker Configure

    module.exports = handler: ->
      ctx_iptables = @contexts('masson/core/iptables', require('../../core/iptables/configure').handler).filter (ctx) => ctx.config.host is @config.host 
      docker = @config.docker ?= {}
      docker.nsenter ?= true
      # Command-line options only supplied to the Docker server when it starts 
      # up, and cannot be changed once it is running.
      # see https://docs.docker.com/v1.5/articles/networking/
      docker.other_args ?= {}
      docker.other_args.iptables ?= if ctx_iptables.length and ctx_iptables[0].config.iptables.action is 'start' then 'true' else 'false'
