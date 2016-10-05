
# Anaconda Install

Install anaconda.

    module.exports = header: 'Anaconda # Install', timeout: -1, handler: ->
      {anaconda} = @config
      @call unless_exec: "#{anaconda.install_dir}/python#{anaconda.python_version}/bin/python --version | grep #{anaconda.version}", handler: ->
        script = "#{anaconda.tmp_dir}/Anaconda-#{anaconda.version}-Linux-x86_64.sh"
        @mkdir anaconda.tmp_dir
        @mkdir anaconda.install_dir
        @mkdir path.join anaconda.install_dir, anaconda.python_version
        @file.download
          source: anaconda.source
          target: script
          md5: true
        @chmod
          target: script
          mode: 0o755
        @execute
          cmd: "#{script} -b -f -p #{anaconda.install_dir}/#{anaconda.python_version}"
        @remove target: script

## Dependencies

    path = require 'path'
