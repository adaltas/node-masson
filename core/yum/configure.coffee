
export default (service) ->
  options = service.options
  # Configuration
  options.fqdn = service.node.fqdn
  options.merge ?= true
  options.config ?= {}
  options.config.main ?= {}
  options.config.main.keepcache ?= '0'
  # Update installed packages
  options.update ?= false
  # Proxy Configuration
  options.proxy ?= false
  if service.deps.proxy and options.proxy
    options.config.main.proxy ?= service.deps.proxy.config.proxy.http_proxy_no_auth
    options.config.main.proxy_username ?= service.deps.proxy.config.proxy.username
    options.config.main.proxy_password ?= service.deps.proxy.config.proxy.password
  # System Repository
  options.repo ?= {}
  options.repo.source ?= null
  options.repo.update ?= true
  options.repo.clean ?= 'CentOS*'
  options.repo.target ?= '/etc/yum.repos.d/centos.repo'
  # Epel Repository
  options.epel ?= {}
  options.epel.enabled ?= false
  if options.epel?.enabled
    options.epel.url ?= null
    options.epel.source ?= null
    options.epel.url = null if options.epel.source?
  # Default Packages
  options.packages ?= {}
  options.packages['yum-plugin-priorities'] ?= true
  options.packages['man'] ?= true
  options.packages['ksh'] ?= true
  # Command Specific
  # Ensure "prepare" is executed locally only once
  options.prepare = service.node.id is service.instances[0].node.id
