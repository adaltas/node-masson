
# System Configure

## Options

The module accept the following properties:

* `profile` (object)   
  Object where keys are the script filename and values are the script content.    
* `limits` (object)   
* `groups` (object)   
* `reboot` (boolean)   
  Reboot the system in case selinux was modified, default is "false"
* `selinux` (boolean|string)   
  Activate or desactivate SeLinux, accepted values are "enforcing", "permissive" and "disabled"
* `users` (object)   

## Default Configuration

```json
{ "system": {
    "selinux": true,
    "reboot": true,
    "limits": {
      "memlock": {
        "hard": 130
      }
    },
    "profile": {},
    "groups": {},
    "users": {}
} }
```

## Example

```json
{ "system": {
    "selinux": true,
    "reboot": true,
    "limits": {
      "nproc": 2048,
      "nofile": {
        "soft": 2048,
        "hard": 4096
      }
    },
    "profile": {
      "tmout.sh": "export TMOUT=0"
    },
    "groups": {
      "my_group": {
        "uid": 2300,
        "system": true
      }
    },
    "users": {
      "my_user": {
        "uid": 2301,
        "gid": "my_user",
        "groups": ["my_group"],
        "system": true
        "shell": "/bin/bash"
      }
    }
} }
```

    module.exports = ->
      system = @config.system ?= {}
      # SELinux
      system.selinux ?= true
      system.selinux = 'enforcing' if system.selinux is true
      system.selinux = 'disabled' if system.selinux is false
      throw Error "Invalid option \"system.selinux\": #{JSON.stringify system.selinux}" unless system.selinux in ['enforcing', 'permissive', 'disabled']
      # Limits
      system.limits ?= {}
      system.limits.memlock ?= {}
      #system.limits.memlock.soft ?= 130
      system.limits.memlock.hard ?= 130
      # Groups
      system.groups ?= {}
      for name, group of system.groups
        group.name ?= name
      # Users
      system.users ?= {}
      for name, user of system.users
        user.name ?= name
        user.home ?= '/root' if name is 'root'
      # Profile
      @config.profile ?= {}
