
# Cloud9

TODO: rewrite using [the Cloud9 v3 SDK](https://github.com/c9/core/) and
packaged as a Docker container.

    module.exports = ->
      'configure':
        'masson/commons/cloud9/configure'
      'install': [
        'masson/commons/git'
        'masson/commons/nodejs'
        'masson/commons/cloud9/install'
      ]
