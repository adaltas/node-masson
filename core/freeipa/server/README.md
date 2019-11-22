
# FreeIPA Server

## Commands

Lifecycle

```
ipactl --help
Usage: ipactl start|stop|restart|status
```

Debugging

```
ipactl status
journalctl -u dirsrv@{domain}.service -f
```

## Logs files

/var/log/httpd/access_log
/var/log/httpd/access_log-{YYYYMMDD}
/var/log/httpd/error_log
/var/log/httpd/error_log-{YYYYMMDD}

/var/log/ipa/ipactl.log
/var/log/ipa/renew.log
/var/log/ipa/restart.log

/var/log/ipa-custodia.audit.log
/var/log/ipaclient-install.log
/var/log/ipaserver-install.log

/var/log/kadmind.log
/var/log/kadmind.log-{YYYYMMDD}
/var/log/krb5kdc.log
/var/log/krb5kdc.log-{YYYYMMDD}
