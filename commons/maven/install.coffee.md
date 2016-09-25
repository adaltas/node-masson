
# Maven install

    module.exports = header: 'Maven Install', handler: ->
      {maven} = @config
      @file.download
        source: maven.source
        target: '/var/tmp/maven.tar.gz'
      @mkdir
        target: "/usr/ryba"
      @extract
        source: '/var/tmp/maven.tar.gz'
        target: '/usr/ryba'
      @link
        source: "/usr/ryba/#{maven.dirname}"
        target: '/usr/ryba/maven'
      @link
        source: '/usr/ryba/maven/bin/mvn'
        target: '/usr/ryba/bin/mvn'
