
# Epel Release Prepare

Download the epel release rpm

    module.exports =
      header: 'Yum Prepare'
      if: (options) -> options.prepare
      ssh: null
      handler: (options) ->
        @file.cache
          header: 'Epel'
          location: true
          md5: options.epel.md5
          sha256: options.epel.sha256
          source: options.epel.url
