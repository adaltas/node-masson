
# Docker Configure

    module.exports = ->
      ctx_iptables = @contexts('masson/core/iptables').filter (ctx) => ctx.config.host is @config.host 
      docker = @config.docker ?= {}
      docker.nsenter ?= true
      # Command-line options only supplied to the Docker server when it starts 
      # up, and cannot be changed once it is running.
      # see https://docs.docker.com/v1.5/articles/networking/
      docker.other_args ?= {}
      docker.other_args.iptables ?= if ctx_iptables.length and ctx_iptables[0].config.iptables.action is 'start' then 'true' else 'false'
      docker.source ?= 'https://github.com/docker/compose/releases/download/1.5.1/docker-compose-Linux-x86_64'
