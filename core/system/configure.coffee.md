
# System Configure

The module accept the following properties:

*   `profile` (object)   
    Object where keys are the script filename and values are the script
    content.    
*   `selinux` (boolean)   
*   `limits` (object)   
*   `groups` (object)   
*   `users` (object)   

Example:

```json
{ "system": {
    "groups": {
      "my_group": {
        "uid": 2300,
        "system": true
      }
    },
    "limits": {
      "a_file": "limit content"
    },
    "profile": {
      "tmout.sh": "export TMOUT=0"
    },
    "selinux": false,
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
