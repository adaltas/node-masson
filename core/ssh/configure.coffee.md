
# SSH Configure

## Parameters

Configuration extends the configuration of the "masson/core/users" with
new properties "authorized\_keys", "rsa" and "rsa_pub" and also define
two new properties "sshd\_config" and "banner".

*   `users.{username}.authorized_keys` (string, array)
    A list of SSH public keys added to the "~/.ssh/authorized_keys" file, optional.
*   `users.{username}.rsa` (string)
    Private SSH key of the user, optional.
*   `users.{username}.rsa_pub` (string)
    Public SSH key of the user, optional.
*   `ssh.sshd_config` (object)
    Configure the SSH daemon by updating the "/etc/ssh/sshd_config" file with
    key/value properties, optional.
*   `ssh.banner` (object)
    Write a banner file in the system and register it with the "/etc/ssh/sshd_config" file, optional.

## Example

```json
{
  "ssh": {
    "sshd_config": {
      "UsePAM": "yes",
      "Port": 2222
    },
    "banner": {
      "target": "/etc/banner",
      "content": "Welcome to Hadoop!"
    },
    "users": {
      "root": {
        "authorized_keys": [ "ssh-rsa AAAA...ZZZZ me@email.com" ],
        "rsa": "-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCA...PKToe4z7C9BqMT7Og==\n-----END RSA PRIVATE KEY-----",
        "rsa_pub": "ssh-rsa AAAA...YYYY user@hadoop"
      },
      "sweet": {
        "home": "/home/sweet",
        "authorized_keys": [ "ssh-rsa AAAA...XXXX you@email.com" ]
      }
    },
  }
}
```

    module.exports = ({options, deps}) ->
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

## Dependencies

    {merge} = require 'mixme'
