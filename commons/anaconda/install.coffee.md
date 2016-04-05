
# Anaconda Install

Install anaconda from previously builded archive.
Installation will fail unless prepare is called before.

    module.exports = header: 'Anaconda # Install', timeout: -1, handler: ->
      {anaconda} = @config
      tmp_archive = "/tmp/#{path.basename anaconda.archive}"
      @download
        source: anaconda.archive
        destination: tmp_archive
        md5: true
        unless_exists: "#{anaconda.install_dir}/anaconda/LICENSE.txt"
      @extract
        source: tmp_archive
        destination: anaconda.install_dir
        preserve_owner: false
        unless_exists: "#{anaconda.install_dir}/anaconda/LICENSE.txt"
      @remove destination: tmp_archive

## Dependencies

    path = require 'path'
