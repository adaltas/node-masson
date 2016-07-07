
# Anaconda Prepare

    module.exports = header: 'Anaconda Build Archive', timeout: -1,  handler: ->
      {anaconda} = @config
      script = "/tmp/#{path.basename anaconda.source}"
      @download
        source: anaconda.source
        target: script
      @chmod
        target: script
        mode: 0o755
      @execute
        cmd: "#{script} -b -p #{anaconda.build_dir}"
      @compress
        source: anaconda.build_dir
        target: anaconda.archive
      @remove target: script
      @remove target: anaconda.build_dir

## Dependencies

    path = require 'path'
