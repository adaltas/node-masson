
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

    module.exports = ->
      [system_ctx] = @contexts('masson/core/system').filter (ctx) => ctx.config.host is @config.host
      options = @config.ssh ?= {}
      options.sshd_config ?= null
      for username, user of options.users
        user.home = system_ctx.config.system.users[user]?.home or "/home/#{username}"
        user.authorized_keys ?= []
        user.authorized_keys = [user.authorized_keys] if typeof user.authorized_keys is 'string'
