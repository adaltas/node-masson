
# OpenLDAP ACL

    export default header: 'OpenLDAP Server HA', handler: ({options}) ->
    
      db = switch options.backend
        when 'mdb' then 'olcDatabase={3}mdb'
        when 'hdb' then 'olcDatabase={2}hdb'
      return unless Object.keys(options.server_ids).length > 1

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
        dn: olcOverlay=syncprov,#{db},cn=config
        objectClass: olcOverlayConfig
        objectClass: olcSyncProvConfig
        olcOverlay: syncprov
        olcSpSessionLog: 100
        EOF
        """

      # TODO: create replication user instead of root_dn
      serverId = "#{options.server_ids[options.fqdn]}"
      
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
        
        dn: #{db},cn=config
        changetype: modify
        add: olcSyncRepl
        olcSyncRepl: rid=#{pad 3, serverId, '0'} 
         provider=#{options.remote_provider} 
         bindmethod=simple 
         binddn="#{options.root_dn}" 
         credentials=#{options.root_password} 
         searchbase="#{options.suffix}" 
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
