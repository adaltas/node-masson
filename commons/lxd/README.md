
# LXD

LXD is a next generation system container manager. It offers a user experience 
similar to virtual machines but using Linux containers instead.

## User & groups

By default, the "lxd" package create the following entries:

```bash
cat /etc/passwd | grep lxd
lxd:x:999:100::/var/snap/lxd/common/lxd:/bin/false
cat /etc/group | grep lxd
lxd:x:1001:ubuntu
```
