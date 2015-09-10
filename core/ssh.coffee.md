
# SSH

    misc = require 'mecano/lib/misc'
    each = require 'each'
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/users'
    exports.push 'masson/core/yum'

## Configuration

Configuration extends the configuration of the "masson/core/users" with
new properties "authorized\_keys", "rsa" and "rsa_pub" and also define
two new properties "sshd\_config" and "banner".

*   `users.[].authorized_keys` (string, array)
    A list of SSH public keys added to the "~/.ssh/authorized_keys" file, optional.
*   `users.[].rsa` (string)
    Private SSH key of the user, optional.
*   `users.[].rsa_pub` (string)
    Public SSH key of the user, optional.
*   `ssh.sshd_config` (object)
    Configure the SSH daemon by updating the "/etc/ssh/sshd_config" file with
    key/value properties, optional.
*   `ssh.banner` (object)
    Write a banner file in the system and register it with the "/etc/ssh/sshd_config" file, optional.


```json
{
  "users": [{
    "name": "root"
    "authorized_keys": [ "ssh-rsa AAAA...ZZZZ me@email.com" ],
    "rsa": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCA...PKToe4z7C9BqMT7Og==\n-----END RSA PRIVATE KEY-----"
    "rsa_pub": "ssh-rsa AAAA...YYYY user@hadoop"
  },{
    "name": "sweet"
    "home": "/home/sweet"
    "authorized_keys": [ "ssh-rsa AAAA...XXXX you@email.com" ]
  }]
  "ssh": {
    "sshd_config": {
      "UsePAM": "yes"
      "Port": 2222
    },
    "banner": {
      "destination": "/etc/banner",
      "content": "Welcome to Hadoop!"
    }
  }
}
```

    exports.configure = (ctx) ->
      require('./users').configure ctx
      ctx.config.ssh ?= {}
      ctx.config.ssh.sshd_config ?= null
      for _, user of ctx.config.users
        user.authorized_keys ?= []
        user.authorized_keys = [user.authorized_keys] if typeof user.authorized_keys is 'string'

## Authorized Keys

Update the "~/.ssh/authorized_keys" file for each users and add the public SSH keys
defined inside "users.[].authorized_keys".

    exports.push name: 'SSH # Authorized Keys', timeout: -1, handler: ->
      users = for _, user of @config.users then user
      for _, user of users
        @mkdir
          destination: "#{user.home or '/home/'+user.name}/.ssh"
          uid: user.name
          gid: null
          mode: 0o0700 # was "permissions: 16832"
        @write
          destination: "#{user.home or '/home/'+user.name}/.ssh/authorized_keys"
          write: for key in user.authorized_keys
            match: new RegExp ".*#{misc.regexp.escape key}.*", 'mg'
            replace: key
            append: true
          uid: user.name
          gid: null
          mode: 0o600
          eof: true

## Configure

Configure the SSH daemon by updated the "/etc/ssh/sshd_config" file with the
properties found in the "ssh.sshd_config" object.

    exports.push
      name: 'SSH # Configure'
      timeout: -1
      if: -> @config.ssh.sshd_config
      handler: ->
        @write
          write: for k, v of @config.ssh.sshd_config
            match: new RegExp "^#{k}.*$", 'mg'
            replace: "#{k} #{v}"
            append: true
          destination: '/etc/ssh/sshd_config'
        @service
          srv_name: 'sshd'
          action: 'restart'
          if: -> @status -1

## Public and Private Key

Deploy user SSH keys. The private key is defined by the "users.[].rsa"
propery and is written in "~/.ssh/id\_rsa". The public key is defined by
the "users.[].rsa\_pub" propery and is written in "~/.ssh/id\_rsa.pub".

    exports.push name: 'SSH # Public and Private Key', timeout: -1, handler: ->
      users = for _, user of @config.users then user
      for _, user of users
        throw Error "Property rsa_pub required if rsa defined" if user.rsa and not user.rsa_pub
        throw Error "Property rsa required if rsa_pub defined" if user.rsa_pub and not user.rsa
        @write
          if: user.rsa
          destination: "#{user.home or '/home/'+user.name}/.ssh/id_rsa"
          content: user.rsa
          uid: user.name
          gid: null
          mode: 0o600
        @write
          if: user.rsa
          destination: "#{user.home or '/home/'+user.name}/.ssh/id_rsa.pub"
          content: user.rsa_pub
          uid: user.name
          gid: null
          mode: 0o600

# Banner

Write the banner file in the system and register it with the SSH
daemon configuration file. The banner is a short message which appear
on the console once a user successfull logged-in with SSH. The "sshd"
service will be restarted if this action had any effect.

    exports.push
      name: 'SSH # Banner'
      timeout: 100000
      if: -> @config.ssh.banner
      handler: ->
        {banner} = @config.ssh
        banner.content += '\n\n' if banner.content
        @write
          destination: banner.destination
          content: banner.content
        @write
          match: new RegExp "^Banner.*$", 'mg'
          replace: "Banner #{banner.destination}"
          append: true
          destination: '/etc/ssh/sshd_config'
        @service
          srv_name: 'sshd'
          action: 'restart'
          if: -> @status()
