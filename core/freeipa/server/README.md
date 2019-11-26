
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

## Directory

Kerberos logs "krb5kdc" can grow large. [Configuring logrotate](http://www.rjsystems.nl/en/2100-kerberos-master.php) seems like an appropriate option. Also, checkout the tomcat-pki logs.

```
rm -rf /var/log/krb5kdc.log*
rm -rf /var/log/pki/pki-tomcat/*.log
rm -rf /var/log/pki/pki-tomcat/*.txt
```

## Logs files

* /var/log/httpd/access_log
* /var/log/httpd/access_log-{YYYYMMDD}
* `/var/log/httpd/error_log`   
  `/var/log/httpd/error_log-{YYYYMMDD}`   
  FreeIPA API call logs (and Apache errors)

* /var/log/ipa/ipactl.log
* /var/log/ipa/renew.log
* /var/log/ipa/restart.log

* /var/log/ipa-custodia.audit.log
* /var/log/ipaclient-install.log
* /var/log/ipaserver-install.log

* `/var/log/kadmind.log`   
  `/var/log/kadmind.log-{YYYYMMDD}`   
* `/var/log/krb5kdc.log`
  `/var/log/krb5kdc.log-{YYYYMMDD}`   
  FreeIPA KDC utilization

* `/var/log/dirsrv/slapd-$REALM/access`   
  Directory Server utilization
* `/var/log/dirsrv/slapd-$REALM/errors`   
  Directory Server errors (including mentioned replication errors)
* `/var/log/pki/pki-tomcat/catalina.{YYYY-MM-DD}.log`
  `/var/log/pki/pki-tomcat/host-manager.{YYYY-MM-DD}.log`
  `/var/log/pki/pki-tomcat/localhost.{YYYY-MM-DD}.log`
  `/var/log/pki/pki-tomcat/localhost_access_log.{YYYY-MM-DD}.log`
  `/var/log/pki/pki-tomcat/manager.{YYYY-MM-DD}.log`
  FreeIPA PKI logs
* `/var/log/pki/pki-tomcat/ca/transactions`   
  FreeIPA PKI transactions logs

Client logs:

* `/var/log/sssd/*.log`   
  SSSD logs (multiple, for all tracked logs)
* `/var/log/audit/audit.log`   
  User login attempts
* `/var/log/secure`   
  Reasons why user login failed
