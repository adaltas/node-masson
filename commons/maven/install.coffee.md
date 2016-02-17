
# Maven install

    module.exports = header: 'Maven Install', handler: ->
      {maven} = @config
      @download
        source: maven.source
        destination: '/var/tmp/maven.tar.gz'
      @mkdir
        destination: "/usr/ryba"
      @extract
        source: '/var/tmp/maven.tar.gz'
        destination: '/usr/ryba'
      @link
        source: "/usr/ryba/#{maven.dirname}"
        destination: '/usr/ryba/maven'
      @link
        source: '/usr/ryba/maven/bin/mvn'
        destination: '/usr/ryba/bin/mvn'
