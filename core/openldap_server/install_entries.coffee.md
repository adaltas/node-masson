
# OpenLDAP Install Entries

    export default header: 'OpenLDAP Server Entries', handler: ({options}) ->

## Groups

Insert LDAP group entries.

      for name, group of options.entries.groups
        @ldap.add
          header: "Group #{name}"
          uri: true
          binddn: options.root_dn
          passwd: options.root_password
          entry: group

## Users

Insert LDAP user entries.

      for name, user of options.entries.users
        @ldap.user
          header: "User #{name}"
          uri: true
          binddn: options.root_dn
          passwd: options.root_password
          user: user
