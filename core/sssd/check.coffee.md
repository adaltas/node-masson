

    exports = module.exports = []
    exports.push require('./').configure

## Check NSS

Check if NSS is correctly configured by executing the command `getent passwd
$user`. The command is only executed if a test user is defined by the
"sssd.test_user" property.

    exports.push name: 'SSSD # Check NSS', handler: (ctx, next) ->
      {test_user} = ctx.config.sssd
      return next() unless test_user
      # ctx.fs.exists '/var/db/masson/sssd_getent_passwd', (err, exists) ->
      ctx
      .execute
        cmd: "getent passwd #{test_user}"
      # .touch
      #   destination: '/var/db/masson/sssd_getent_passwd'
      .then next

## Check PAM

Check if PAM is correctly configured by executing the command
`sh -l $user -c 'whoami'`. This is only executed if a test
user is defined by the "sssd.test_user" property.

    exports.push name: 'SSSD # Check PAM', handler: (ctx, next) ->
      {test_user} = ctx.config.sssd
      return next() unless test_user
      ctx.execute
        cmd: "su -l #{test_user} -c 'whoami'"
      .then next