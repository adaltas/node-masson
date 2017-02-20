
# Maven install

    module.exports = header: 'Maven Install', handler: ->
      {maven} = @config
      @file.download
        source: maven.source
        target: '/var/tmp/maven.tar.gz'
      @system.mkdir
        target: "/usr/ryba"
      @extract
        source: '/var/tmp/maven.tar.gz'
        target: '/usr/ryba'
      @system.link
        source: "/usr/ryba/#{maven.dirname}"
        target: '/usr/ryba/maven'
      @system.link
        source: '/usr/ryba/maven/bin/mvn'
        target: '/usr/ryba/bin/mvn'
