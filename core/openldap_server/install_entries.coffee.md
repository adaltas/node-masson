
# OpenLDAP Install Entries

    module.exports = header: 'OpenLDAP Server Entries', handler: ->
      {openldap_server} = @config
      for name, group of openldap_server.entries.groups
        @ldap.add
          header: "Group #{name}"
          uri: true
          binddn: openldap_server.root_dn
          passwd: openldap_server.root_password
          entry: group
      for name, user of openldap_server.entries.users
        @ldap.user
          header: "User #{name}"
          uri: true
          binddn: openldap_server.root_dn
          passwd: openldap_server.root_password
          user: user
