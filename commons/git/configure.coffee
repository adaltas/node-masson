import { merge } from 'mixme'

export default (service) ->
  options = service.options
  # Environment
  options.merge ?= true
  options.proxy ?= true
  options.global ?= false
  options.global = {} if options.global is true
  # Configuration
  options.properties ?= {}
  options.properties.http ?= {}
  options.properties.http.proxy ?= service.deps.proxy.options.http_proxy if service.deps.proxy and options.proxy
  # User Configuration
  # Npm properties can be defined by the system module through the "gitconfig" user 
  # configuration.
  options.users ?= {}
  for username, user of options.users
    throw Error "User Not Defined: module system must define the user #{username}" unless service.deps.system.options.users[username]
    user = merge service.deps.system.options.users[username], user
    user.target ?= "#{user.home}/.gitconfig"
    user.uid ?= user.uid or user.name
    user.gid ?= user.gid or user.group
    user.content ?= merge options.properties, user.gitconfig, user.properties
    user.merge ?= options.merge
