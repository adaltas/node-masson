
# SSH Configure

    module.exports = ->
      ssh = @config.ssh ?= {}
      ssh.sshd_config ?= null
      for _, user of @config.system.users
        user.authorized_keys ?= []
        user.authorized_keys = [user.authorized_keys] if typeof user.authorized_keys is 'string'
