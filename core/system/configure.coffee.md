
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
{
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
}
```

## Example

```json
{
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
}
```

    export default (service) ->
      options = service.options
      
## SELinux

      options.selinux ?= true
      options.selinux = 'enforcing' if options.selinux is true
      options.selinux = 'disabled' if options.selinux is false
      throw Error "Invalid option \"options.selinux\": #{JSON.stringify options.selinux}" unless options.selinux in ['enforcing', 'permissive', 'disabled']

## Sysctl

      options.sysctl ?= {}

## Limits

      options.limits ?= {}
      options.limits.memlock ?= {}
      #options.limits.memlock.soft ?= 130
      options.limits.memlock.hard ?= 130

## Identities

      # Groups
      options.groups ?= {}
      for name, group of options.groups
        group.name ?= name
      # Users
      options.users ?= {}
      for name, user of options.users
        user.name ?= name
        user.home ?= '/root' if name is 'root'
      # Profile
      # @config.profile ?= {}
      options
