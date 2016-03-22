
# SSH Install

    module.exports = header: 'SSH Install', handler: ->

## Package

      @service
        name: "openssh-server"
      @service
        name: "openssh-clients"

## Authorized Keys

Update the "~/.ssh/authorized_keys" file for each users and add the public SSH keys
defined inside "users.[].authorized_keys".

      @call header: 'SSH # Authorized Keys', handler: ->
        for _, user of @config.users
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

      @call
        header: 'SSH # Configure'
        if: -> @config.ssh.sshd_config
        handler: ->
          @write
            write: for k, v of @config.ssh.sshd_config
              match: new RegExp "^#{k}.*$", 'mg'
              replace: "#{k} #{v}"
              append: true
            destination: '/etc/ssh/sshd_config'
          @service_restart
            name: 'sshd'
            timeout: -1
            if: -> @status -1

## Public and Private Key

Deploy user SSH keys. The private key is defined by the "users.[].rsa"
propery and is written in "~/.ssh/id\_rsa". The public key is defined by
the "users.[].rsa\_pub" propery and is written in "~/.ssh/id\_rsa.pub".

      @call header: 'SSH # Public and Private Key', timeout: -1, handler: ->
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

## Banner

Write the banner file in the system and register it with the SSH
daemon configuration file. The banner is a short message which appear
on the console once a user successfull logged-in with SSH. The "sshd"
service will be restarted if this action had any effect.

      @call
        header: 'SSH # Banner'
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
          @service_restart
            name: 'sshd'
            if: -> @status()

## Dependencies

    misc = require 'mecano/lib/misc'
