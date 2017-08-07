
# GIT

GIT - the stupid content tracker. The recipe will install
the git client and configure each user. By default, unless
the "global" property is defined, the global property file
in "/etc/gitconfig" will not be created or modified.

    module.exports =
      use:
        'proxy': module: 'masson/core/proxy'
        'system': module:  'masson/core/system'
      configure:
        'masson/commons/git/configure'
      commands:
        'install': [
          'masson/commons/git/install'
        ]
