
export default (service) ->
  options = service.options
  # Configuration
  options.password ?= 'root'
  options.user ?= 'root'
  options.port ?= '5432'
  options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
  # Docker
  options.image_dir ?= "/tmp_#{Date.now()}"
  options.version ?= '9.5'
  options.container_name ?= 'postgres_server'
  # Wait
  options.wait_tcp = {}
  options.wait_tcp.fqdn = service.node.fqdn
  options.wait_tcp.port = options.port
  
