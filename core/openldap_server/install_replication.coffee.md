
## Replication

[Master-Master](http://easylinuxtutorials.blogspot.fr/2013/11/multi-master-replication-of-openldap.html)

    module.exports = header: 'OpenLDAP Server # Replication', timeout: -1, handler: ->
      {suffix, config_file, bdb_file, active_host, root_dn, root_password} = @config.openldap_server
      master_uri = @contexts('masson/core/openldap_server').filter((ctx) ->
        ctx.config.host is active_host
      )[0].config.openldap_server.uri
      # slave_uri = @contexts('masson/core/openldap_server').filter((ctx) ->
      #   ctx.config.host isnt active_host
      # )[0].config.openldap_server.uri
      replication_binddn = "cn=Manager,#{suffix}"
      replication_bindpw = 'test'
      # replication_binddn = "cn=replication,ou=systeme,#{suffix}"
      # replication_bindpw = 'ldap123replicattion'
      # @wait_execute
      #   unless: @config.host is active_host
      #   cmd: """
      #   ldapsearch -H "#{master_uri}" -D "#{replication_binddn}" -w "#{replication_bindpw}" -b "#{suffix}"
      #   """
      #   code_skipped: 255
      @write
        if: -> @config.host is active_host
        destination: bdb_file
        write: [
          match: /^olcOverlay:.*syncprov$/m
          replace: "olcOverlay: {0}syncprov"
          before: "structuralObjectClass"
          append: true
        ]
      @write
        unless: -> @config.host is active_host
        destination: bdb_file
        write: [
          match: /^olcSyncrepl:.*$/m
          replace: "olcSyncrepl: {0}rid=31 provider=\"#{master_uri}\" searchbase=\"#{suffix}\" type=\"refreshAndPersist\" retry=\"120 +\" timeout=\"5\" bindmethod=\"simple\" tls_cacertdir=\"/etc/openldap/cacerts\" binddn=\"#{replication_binddn}\" credentials=\"#{replication_bindpw}\""
          append: true
        ,
          match: /^olcUpdateRef:.*$/m
          replace: "olcUpdateRef: #{master_uri}"
          append: true
        ]
      @write
        destination: config_file
        write: [
          match: /^olcModulePath:.*$/m
          replace: "olcModulePath: /usr/lib64/openldap"
          append: true
        ,
          match: /^olcModuleLoad:.*syncprov$/m
          replace: "olcModuleLoad: {0}syncprov"
          append: true
        # ,
        #   match: /^olcModuleLoad:.*ppolicy$/m
        #   replace: "olcModuleLoad: {1}ppolicy"
        #   append: true
        ]
      # @execute
      #   if: -> @config.host is active_host
      #   cmd: """
      #   replication_bindpw_sha=`slappasswd -s #{replication_bindpw}`
      #   ldapadd -c -H ldapi:/// -D #{root_dn} -w #{root_password} <<-EOF
      #   dn: ou=systeme,#{suffix}
      #   ou: Systeme
      #   objectClass: top
      #   objectClass: organizationalUnit
      # 
      #   dn: #{replication_binddn}
      #   objectClass: top
      #   objectClass: person
      #   cn: replication
      #   sn: replication
      #   userPassword: $replication_bindpw_sha
      #   EOF
      #   """
      #   code_skipped: 68
      # @ldap_acl
      #   if: -> @config.host is active_host
      #   suffix: suffix
      #   acls: [
      #     to: 'attrs=userPassword'
      #     by: [
      #       "dn.exact=\"#{replication_binddn}\" read"
      #       "* read"
      #     ]
      #     first: true
      #   ,
      #     to: "*"
      #     by: [
      #       "dn.exact=\"#{replication_binddn}\" manage"
      #       "* read"
      #     ]
      #     first: true
      #   ]
      @execute
        cmd: """
        ldapsearch -H "#{master_uri}" -D "#{replication_binddn}" -w "#{replication_bindpw}" -b "#{suffix}"
        """
        shy: true
        stdout: null
      @service
        srv_name: 'slapd'
        action: 'restart'
        if: -> @status()
