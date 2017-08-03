
# Cloud9 Install

    module.exports = header: 'Cloud9 Install', handler: (options) ->

Install the libxml2 package and the SM plugin manager using NPM.

      @service name: 'libxml2-devel'
      @system.execute cmd: 'npm install -g sm'

Download source code from github.

      @tools.git
        source: options.github
        target: '/usr/lib/cloud9'

Run package installation.

      # TODO: detect previous install of sm
      @system.execute
        cmd: 'sm install'
        cwd: '/usr/lib/cloud9'
