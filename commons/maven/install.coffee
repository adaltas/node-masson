
export default
  metadata:
    header: 'Maven Install'
  handler: (options) ->
    @file.download
      source: options.source
      target: '/var/tmp/maven.tar.gz'
    @system.mkdir
      target: "/usr/ryba"
    @tools.extract
      source: '/var/tmp/maven.tar.gz'
      target: '/usr/ryba'
    @system.link
      source: "/usr/ryba/#{options.dirname}"
      target: '/usr/ryba/maven'
    @system.link
      source: '/usr/ryba/maven/bin/mvn'
      target: '/usr/ryba/bin/mvn'
