
# SSH Install

    module.exports = header: 'SSH Install', handler: ({options}) ->

## Package

      @call header: 'Packages', ->
        @service
          name: 'openssh-server'
        @service
          if_os: name: ['redhat','centos']
          name: 'openssh-clients'
        @service
          if_os: name: ['ubuntu']
          name: 'openssh-client'

## Authorized Keys

Update the "~/.ssh/authorized_keys" file for each users and add the public SSH keys
defined inside "users.[].authorized_keys".

      @call
        header: 'Authorized Keys'
      , ->
        for username, user of options.users
          @system.mkdir
            target: "#{user.ssh_dir}"
            uid: user.name
            gid: undefined
            mode: 0o0700 # was "permissions: 16832"
          @file
            target: "#{user.ssh_dir}/authorized_keys"
            write: for key in user.authorized_keys
              match: new RegExp ".*#{misc.regexp.escape key}.*", 'mg'
              replace: key
              append: true
            uid: username
            gid: undefined
            mode: 0o0600
            eof: true

## Configure

Configure the SSH daemon by updated the "/etc/ssh/sshd_config" file with the
properties found in the "ssh.sshd_config" object.

      @call
        header: 'Configure'
        if: -> options.sshd_config
      , ->
        @file
          write: for k, v of options.sshd_config
            match: new RegExp "^#{k}.*$", 'mg'
            replace: "#{k} #{v}"
            append: true
          target: '/etc/ssh/sshd_config'
        @service.restart
          name: 'sshd'
          if: -> @status -1

## Public and Private Key

Deploy user SSH keys. The private key is defined by the "users.[].rsa"
propery and is written in "~/.ssh/id\_rsa". The public key is defined by
the "users.[].rsa\_pub" propery and is written in "~/.ssh/id\_rsa.pub".

      @call
        header: 'Public and Private Key'
      , ->
        users = for _, user of options.users then user
        for username, user of users
          throw Error "Property rsa_pub required if rsa defined" if user.rsa and not user.rsa_pub
          throw Error "Property rsa required if rsa_pub defined" if user.rsa_pub and not user.rsa
          @file
            if: user.rsa
            target: "#{user.ssh_dir}/id_rsa"
            content: user.rsa
            uid: username
            gid: undefined
            mode: 0o600
          @file
            if: user.rsa
            target: "#{user.ssh_dir}/id_rsa.pub"
            content: user.rsa_pub
            uid: username
            gid: undefined
            mode: 0o600

## Banner

Write the banner file in the system and register it with the SSH
daemon configuration file. The banner is a short message which appear
on the console once a user successfull logged-in with SSH. The "sshd"
service will be restarted if this action had any effect.

      @call
        header: 'Banner'
        if: -> options.banner
      , ->
        options.banner.content += '\n\n' if options.banner.content
        @file
          target: options.banner.target
          content: options.banner.content
        @file
          match: new RegExp "^Banner.*$", 'mg'
          replace: "Banner #{options.banner.target}"
          append: true
          target: '/etc/ssh/sshd_config'
        @service.restart
          name: 'sshd'
          if: -> @status()

## Dependencies

    misc = require '@nikitajs/core/lib/misc'
