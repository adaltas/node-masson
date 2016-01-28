
# Anaconda Install

Install anaconda from previously builded archive.
Installation will fail unless prepare is called before.

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Install archive

    module.exports.push header: 'Anaconda # Install', timeout: -1, handler: ->
      {anaconda} = @config
      tmp_archive = "/tmp/#{path.basename anaconda.archive}"
      @upload
        source: anaconda.archive
        destination: tmp_archive
        binary: true
        unless_exists: "#{anaconda.install_dir}/anaconda"
      @extract
        source: tmp_archive
        destination: anaconda.install_dir
        unless_exists: "#{anaconda.install_dir}/anaconda"

## Dependencies

    path = require 'path'

