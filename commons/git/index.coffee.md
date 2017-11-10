
# GIT

GIT - the stupid content tracker. The recipe will install
the git client and configure each user. By default, unless
the "global" property is defined, the global property file
in "/etc/gitconfig" will not be created or modified.

    module.exports =
      deps:
        'system': module: 'masson/core/system', local: true
        'proxy': module: 'masson/core/proxy', local: true
      configure:
        'masson/commons/git/configure'
      commands:
        'install':
          'masson/commons/git/install'
