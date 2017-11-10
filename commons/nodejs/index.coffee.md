
# Node.js

Deploy multiple version of [NodeJs] using [N].

It depends on the "masson/core/git" and "masson/commons/users" modules. The former
is used to download n and the latest is used to write a "~/.npmrc" file in the
home of each users.

    module.exports =
      deps:
        proxy: module: 'masson/core/proxy', local: true
        users: module: 'masson/core/users', local: true
        git: module: 'masson/commons/git', local: true
      configure:
        'masson/commons/nodejs/configure'
      commands:
        install:
          'masson/commons/nodejs/install'

[nodejs]: http://www.nodejs.org
[n]: https://github.com/visionmedia/n
