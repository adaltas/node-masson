
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

    module.exports = (service) ->
      options = service.options
      
      options.sshd_config ?= null
      options.users ?= {}
      for username, config of options.users
        throw Error "User Not Defined: module system must define the user #{username}" unless username is 'root' or service.deps.system.options.users[username]
        user = merge {}, service.deps.system.options.users[username] or {}, config
        user.home ?= '/root' if username is 'root'
        config.ssh_dir ?= "#{user.home}/.ssh"
        config.authorized_keys ?= []
        config.authorized_keys = [config.authorized_keys] if typeof config.authorized_keys is 'string'

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
