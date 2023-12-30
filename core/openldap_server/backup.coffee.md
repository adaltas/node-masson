
# OpenLDAP Server Backup

Backup strategies largely depend on the amount of change in the database and how
much of that change an administrator might be willing to lose in a catastrophic failure. 
There are two basic methods that can be used:

*   Backup the Berkeley database itself and periodically back up the transaction log files:

Berkeley DB produces transaction logs that can be used to reconstruct changes from a given 
point in time. For example, if an administrator were willing to only lose one hour's worth
of changes, they could take down the server in the middle of the night, copy the Berkeley
database files offsite, and bring the server back online. Then, on an hourly basis, they
could force a database checkpoint, capture the log files that have been generated in the
past hour, and copy them offsite. The accumulated log files, in combination with the previous
database backup, could be used with db_recover to reconstruct the database up to the time the
last collection of log files was copied offsite. This method affords good protection,
with minimal space overhead.

*   Periodically run slapcat and back up the LDIF file:

Slapcat can be run while slapd is active. However, one runs the risk of an inconsistent database
- not from the point of slapd, but from the point of the applications using LDAP. 
For example, if a provisioning application performed tasks that consisted of several LDAP operations, 
and the slapcat took place concurrently with those operations, then there might be inconsistencies in
the LDAP database from the point of view of that provisioning application and applications that depended
on it. One must, therefore, be convinced something like that won't happen. One way to do that would be 
to put the database in read-only mode while performing the slapcat. The other disadvantage of this approach 
is that the generated LDIF files can be rather large and the accumulation of the day's backups could add up 
to a substantial amount of space.


    export default header: 'OpenLDAP Server Backup', handler: ->
      @tools.backup
        name: 'openldap'
        cmd: 'slapcat'
