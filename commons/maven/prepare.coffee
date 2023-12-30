
export default
  conditions:
    if: -> @contexts('masson/commons/maven')[0]?.config.host is @config.host
  metadata:
    header: 'Maven Prepare'
    ssh: false
  handler: (options) ->
    @file.cache
      source: "#{options.source}"
      location: true
