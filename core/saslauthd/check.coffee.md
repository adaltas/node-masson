
# SASLAuthd Check

    export default header: 'SASLAuthd Check', handler: ({options}) ->

First check that the DN and password that saslauthd will use when it connects to AD are valid:

```
ldapsearch -x -H ldap://dc1.example.com/ \
    -D cn=saslauthd,cn=Users,DC=ad,DC=example,DC=com \
    -w secret \
    -b '' \
    -s base
```

Next check that a sample AD user can be found:

```
ldapsearch -x -H ldap://dc1.example.com/ \
    -D cn=saslauthd,cn=Users,DC=ad,DC=example,DC=com \
    -w secret \
    -b cn=Users,DC=ad,DC=example,DC=com \
    "(userPrincipalName=user@ad.example.com)"
```

Check that the user can bind to AD:

```
ldapsearch -x -H ldap://dc1.example.com/ \
    -D cn=user,cn=Users,DC=ad,DC=example,DC=com \
    -w userpassword \
    -b cn=user,cn=Users,DC=ad,DC=example,DC=com \
    -s base \
      "(objectclass=*)"
```

If all that works then saslauthd should be able to do the same:

```
testsaslauthd -u user@ad.example.com -p userpassword
testsaslauthd -u user@ad.example.com -p wrongpassword
```

      @execute
        header: 'Cmd testsaslauthd'
        if: options.check.username
        cmd: "testsaslauthd -u #{options.check.username} -p #{options.check.password}"
