
export default ({deps, options, node, instances}) ->
  options.ip = node.ip
  options.fqdn = node.fqdn
  options.hostname = node.hostname
  throw Error 'Both resolv and systemd_resolv cannot be set at the same time' if options.resolv and options.systemd_resolv
  # Hosts
  options.hosts_auto ?= false
  options.own_host ?= false # For when fqdn of the current host is already in /etc/hosts, we will want to avoid duplication
  options.hosts ?= {}
  options.host_replace ?= {}
  options.hostname_disabled ?= true
  if options.hosts_auto then for instance in instances
    throw Error "Required Property: node must define an IP" unless instance.node.ip
    options.hosts[instance.node.ip] = "#{instance.node.fqdn} #{instance.node.hostname}" unless instance.node.ip is options.ip and options.own_host
  options.host_auto ?= false
  if options.host_auto
    throw Error "Required Property: node must define an IP" unless node.ip
    options.host_replace[node.ip] = "#{node.fqdn} #{node.hostname}"
  # DNS Resolver
  if deps.bind_server
    options.dns = for bind in deps.bind_server
      continue if bind.node.host is node.host
      host: bind.node.host
      port: bind.options.port
