
# OpenLDAP ACL

    module.exports = header: 'OpenLDAP Server HA', handler: ->
      {openldap_server} = @config
      return unless Object.keys(openldap_server.server_ids).length > 1

      @system.execute
        header: 'Module Install'
        unless_exec: """
        ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" | \
        grep -E "^olcModulePath: /usr/lib64/openldap"
        """
        cmd: """
        ldapadd -Y EXTERNAL -H ldapi:/// <<-EOF
        dn: cn=module,cn=config
        objectClass: olcModuleList
        cn: module
        olcModulePath: /usr/lib64/openldap
        olcModuleLoad: syncprov.la
        EOF
        """

      @system.execute
        header: 'Module Activation'
        unless_exec: """
        ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" | \
        grep -E "^olcOverlay:.*syncprov"
        """
        cmd: """
        ldapadd -Y EXTERNAL -H ldapi:/// <<-EOF
        dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
        objectClass: olcOverlayConfig
        objectClass: olcSyncProvConfig
        olcOverlay: syncprov
        olcSpSessionLog: 100
        EOF
        """

      # TODO: create replication user instead of root_dn
      serverId = "#{openldap_server.server_ids[@config.host]}"
      @system.execute
        header: 'Registration'
        unless_exec: """
        ldapsearch -Y EXTERNAL -H ldapi:/// -b "cn=config" \
        | grep -E "^olcSyncrepl:.*rid="
        """
        cmd: """
        ldapmodify -Y EXTERNAL -H ldapi:/// <<-EOF
        dn: cn=config
        changetype: modify
        replace: olcServerID
        olcServerID: #{serverId}
        
        dn: olcDatabase={2}hdb,cn=config
        changetype: modify
        add: olcSyncRepl
        olcSyncRepl: rid=#{pad 3, serverId, '0'} 
         provider=#{openldap_server.remote_provider} 
         bindmethod=simple 
         binddn="#{openldap_server.root_dn}" 
         credentials=#{openldap_server.root_password} 
         searchbase="#{openldap_server.suffix}" 
         scope=sub 
         schemachecking=on 
         type=refreshAndPersist 
         retry="30 5 300 3" 
         interval=00:00:05:00
        -
        add: olcMirrorMode
        olcMirrorMode: TRUE
        EOF
        """

## Dependencies

    pad = require 'pad'
