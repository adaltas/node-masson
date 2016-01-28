
# Anaconda Build

    module.exports = []
    module.exports.push 'masson/bootstrap/log'

## Build Prepare

    module.exports.push header: 'Anaconda # Build Archive', timeout: -1,  handler: ->
      {anaconda} = @config
      script = "/tmp/#{path.basename anaconda.source}"
      @download
        source: anaconda.source
        destination: script
      @chmod
        destination: script
        mode: 0o755
      @execute
        cmd: "#{script} -b -p #{anaconda.build_dir}"
      @compress
        source: anaconda.build_dir
        destination: anaconda.archive
      @remove destination: script
      @remove destination: anaconda.build_dir

## Dependencies

    path = require 'path'