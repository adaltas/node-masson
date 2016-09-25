
# Anaconda Install

Install anaconda.

    module.exports = header: 'Anaconda # Install', timeout: -1, handler: ->
      {anaconda} = @config
      @call unless_exec: "#{anaconda.install_dir}/bin/python --version | grep #{anaconda.version}", handler: ->
        script = "#{anaconda.tmp_dir}/Anaconda3-#{anaconda.version}-Linux-x86_64.sh"
        @file.download
          source: anaconda.source
          target: script
          md5: true
          unless_exec: 
        @chmod
          target: script
          mode: 0o755
        @execute
          cmd: "#{script} -b -f -p #{anaconda.install_dir}"
        @remove target: script

## Dependencies

    path = require 'path'
