
# SSH Configure

    module.exports = handler: ->
      @config.ssh ?= {}
      @config.ssh.sshd_config ?= null
      for _, user of @config.users
        user.authorized_keys ?= []
        user.authorized_keys = [user.authorized_keys] if typeof user.authorized_keys is 'string'
