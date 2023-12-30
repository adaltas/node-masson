
import {merge} from 'mixme'

export default ({options, deps}) ->
  options.sshd_config ?= null
  options.users ?= {}
  for username, user of options.users
    if deps.system
      throw Error "User Not Defined: module system must define the user #{username}" unless username is 'root' or deps.system.options.users[username]
      if deps.system.options.users[username]?.home
        options.users[username].ssh_dir ?= "#{deps.system.options.users[username].home}/.ssh"
    home = if username is 'root' then '/root' else "/home/#{username}"
    options.users[username].ssh_dir ?= "#{home}/.ssh"
    options.users[username].authorized_keys ?= []
    options.users[username].authorized_keys = [user.authorized_keys] if typeof user.authorized_keys is 'string'
