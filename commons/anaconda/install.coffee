
export default header: 'Anaconda Install', handler: (options) ->
  @each options.python_version, (opts) ->
    version = opts.key
    @call unless_exec: "#{options.install_dir}/python#{version}/bin/python --version 2>&1 | grep #{options.version}", handler: ->
      script = "#{options.tmp_dir}/Anaconda#{version}-#{options.version}-Linux-x86_64.sh"
      @system.mkdir options.tmp_dir
      @system.mkdir options.install_dir
      @system.mkdir "#{options.install_dir}/python#{version}"
      @file.download
        source: options.source["python#{version}"]
        target: script
        md5: true
      @system.chmod
        target: script
        mode: 0o755
      @system.execute
        cmd: "#{script} -b -f -p #{options.install_dir}/python#{version}"
      @system.remove target: script
