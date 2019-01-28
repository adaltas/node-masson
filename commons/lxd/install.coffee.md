
# LXD Install

    module.exports = header: 'LXD Install', handler: ({options}) ->

## User & groups

By default, the "lxd" package create the following entries:

```bash
cat /etc/passwd | grep lxd
lxd:x:999:100::/var/snap/lxd/common/lxd:/bin/false
cat /etc/group | grep lxd
lxd:x:1001:ubuntu
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user
      
      @service header: 'Packages', ['lxd', 'zfsutils-linux']
      
      @system.execute (
        cmd: "#{member}"
      ) for member in options.members
      
      @system.execute
        cmd: """
        cat <<EOF | lxd init --preseed
        #{yaml.safeDump options.init}
        EOF
        """

```
lxc remote add m1 10.10.10.11
lxc launch m1:images:centos/7 second
lxc config device add second eth1 nic name=eth1 nictype=physical parent=enp0s9
lxc exec second -- ip addr
```
        
## Dependencies

    yaml = require 'js-yaml'
