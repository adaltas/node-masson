
# Anaconda Install

Install anaconda.

    module.exports = header: 'Anaconda Install', timeout: -1, handler: ->
      {anaconda} = @config
      @each anaconda.python_version, (options) ->
        version = options.key
        @call unless_exec: "#{anaconda.install_dir}/python#{version}/bin/python --version 2>&1 | grep #{anaconda.version}", handler: ->
          script = "#{anaconda.tmp_dir}/Anaconda#{version}-#{anaconda.version}-Linux-x86_64.sh"
          @mkdir anaconda.tmp_dir
          @mkdir anaconda.install_dir
          @mkdir "#{anaconda.install_dir}/python#{version}"
          @file.download
            source: anaconda.source["python#{version}"]
            target: script
            md5: true
          @chmod
            target: script
            mode: 0o755
          @execute
            cmd: "#{script} -b -f -p #{anaconda.install_dir}/python#{version}"
          @remove target: script
