
# Changelog

## Trunk

* chrony: support new output to print tracking

## Version 0.1.6

* normalize: refactor nodes as instances
* normalize: merge service_by_nodes with nodes
* pki: new commands
* params: merge from config
* server: inject params and split command with lib
* nodes: services as an object
* graph: nodes with humam output
* deps: validate required with local
* context: merge no_ssh with nikita options
* commons/java: update version
* package: release commands
* params: inject custom module loaded
* package: complete engine rewrite
* mariadb: parametrize service name
* context: reflect move in nikita of flatten into array
* all: assert packages are installed and services running
* openldap: add mdb backend support
* run: remove global configuration
* mysql: client repo configuration
* mysql server: fix repo installation
* run: fix history file close
* context: disable ssh auto connect
* package: lock file
* nginx: add nginx cookbook
* ssh: move from global to nikita
* yum: inject clean option from config and clean up
* docker: refresh config and add devicemapper
* log: add massson log archive
* java: comment java 1.7
* run: allow filtering by tags

## Version 0.1.5

* fstab: add disk formating
* krb5 client: fix wait for remote servers
* krb5 server: fix realm init in non ha mode
* mariadb: refactor prepare masson2
* network: added host_replace option
* krb5: HA support
* ssl: install java is keytool is required
* java: raise openjdk version to 1.8.0
* krb5 client: re-activate wait admin
* yum: fix source detection
* mysql: repo declaration per service
* yum: rename repo to source
* saslauthd: fix wrong - sign in checks
* core.epel: move epel install to its own module
* openldap server: fix HA registration
* saslauthd: fix delimiter
* krb5 client: expose server admin information
* run: ability to resume a previous run #20
* saslauthd: check ldap properties if mech is ldap
* mysql: start & stop actions
* src: remove usage of timeout
* krb5 server: admin server url
* krb5: split client & server
* sssd: ldap certificates delegated to openldap client
* openldap: provision users and groups
* ssl: jks keystore and truststore
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
