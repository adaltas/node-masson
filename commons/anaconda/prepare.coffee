
export default
  header: 'Anaconda Prepare'
  if: -> @contexts('masson/commons/anaconda')[0]?.config.host is @config.host
  ssh: false
  handler: (options) ->
    # Download the Anaconda package container
    @each options.python_version, (config) ->
      version = config.key
      @file.cache
        source: options.source["python#{version}"]
        location: true
