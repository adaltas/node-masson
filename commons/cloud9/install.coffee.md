
# Cloud9 Install

    module.exports = header: 'Cloud9 Install', handler: ->
      {proxy, github}} = @config.cloud9

Install the libxml2 package and the SM plugin manager using NPM.

      @service name: 'libxml2-devel'
      @execute cmd: 'npm install -g sm'

Download source code from github.

      @tools.git
        source: cloud9.github
        target: "/usr/lib/cloud9"

Run package installation.

      # TODO: detect previous install of sm
      @execute
        cmd: "sm install"
        cwd: "/usr/lib/cloud9"
