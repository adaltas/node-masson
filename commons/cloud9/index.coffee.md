
# Cloud9

TODO: rewrite using [the Cloud9 v3 SDK](https://github.com/c9/core/) and
packaged as a Docker container.

    module.exports =
      use:
        git: module: 'masson/commons/git', local: true
        nodejs: module: 'masson/commons/nodejs', local: true
      configure:
        'masson/commons/cloud9/configure'
      commands:
        'install': ->
          options = @config.cloud9
          @call 'masson/commons/cloud9/install', options
