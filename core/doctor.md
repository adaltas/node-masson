
# Core Doctor

## Yum database corrupted

Runing yum print: "rpmdb: PANIC: fatal region error detected; run recovery"

### Solution

Follow [Vivek Gite instructions](http://www.cyberciti.biz/faq/centos-rpmdb-panic-fatal-region-error-detected-run-recovery-error-and-solution/)

Backup

```
now=`date +"%m-%d-%Y_%T"`
mkdir /root/backups.rpm.$now
cp -avr /var/lib/rpm /root/backups.rpm.$now
```

Fix

```
rm -f /var/lib/rpm/__db*
db_verify /var/lib/rpm/Packages
rpm --rebuilddb
yum clean all
```

