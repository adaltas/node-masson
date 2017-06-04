
# Changelog

## Trunk

* krb5 client: expose server admin information
* run: ability to resume a previous run #20
* saslauthd: check ldap properties if mech is ldap
* mysql: start & stop actions
* src: remove usage of timeout
* krb5 server: admin server url
* krb5: split client & server
* sssd: ldap certificates delegated to openldap client
* openldap: provision users and groups
* ssl: jks keystore and trustore
* saslauthd: fix mode and indentation
* ntp: handle negative time synchronization
* saslauthd: set user and group
* ssl: use file instead of download
* krb5 server: fix server when a client with no server is defined
* network: use start/end tag to fill host resolution #19
* ssl: new service
* mysql server: wait action
* package: latest dependencies
* krb5 server: provision principals
* sssd: provision user and group
* proxy: new service
* src: fix backup renamed as remove
* exec: print node name instead of host
* saslathd: enable service startup
* ntp: sync before start
* krb5: reduce wait log noise
* mysql: support < and > mysql 5.7 securisation
* mysql: refactor user/group config
* mariadb: refactor user/group config
* params: ambari blueprint command
* mysql server: place run dir inside tempfs
* openldap: ldapsearch exemple to returl acls
* openldap: honors saslauthd
* saslauthd: new service
* ntp: stronger synchronization moved into install
* mysql: improve grant and super permission to root
* run: remove fast option
* openldap: fix log level modification
* krb5: remove unrelevant acl
* mysql 5.7: enforce if_os conditions
* openldap server: ha #8
* replace system.discover by if_os
* mysql: set service name to mysql
* krb5 client: increase interval between checks
* httpd: iptables dependency not implicit
* krb5_server: refactor conf
* run: print multiple exceptions
* mysql: improve/simplify root permission
* mysql: merge my.conf
