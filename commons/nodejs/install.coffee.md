
# Node.js Install

    module.exports = header: 'Node.js Install', handler: (options) ->

## N Installation

N is a Node.js binary management system, similar to nvm and nave. Accoring to 
the tests realized in 2015, proxy env var arent used by ssh exec.

      env = {}
      env.http_proxy = options.config['proxy'] if options.config['proxy']
      env.https_proxy = options.config['https-proxy'] if options.config['https-proxy']
      @system.execute
        header: 'N'
        env: env
        cmd: """
        export http_proxy=#{options.config['proxy'] or ''}
        export https_proxy=#{options.config['https-proxy'] or ''}
        cd /tmp
        git clone https://github.com/visionmedia/n.git
        cd n
        make install
        """
        if: options.method is 'n'
        unless_exists: '/usr/local/bin/n'

## Node.js Installation

Multiple installation of Node.js may coexist with N.

      @system.execute
        header: 'Node.js Installation'
        cmd: "n #{options.version}"
        if: options.method is 'n'

## NPM configuration

Write the "~/.npmrc" file for each user defined by the "masson/core/users" 
module.

      @call header: 'NPM Configuration', ->
        @file.ini (
          if: !!user.config
          target: "#{user.target}"
          content: user.config
          merge: user.merge
          uid: user.uid
          gid: user.gid
        ) for _, user of options.users
