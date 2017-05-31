
# Epel Release Prepare

Download the epel release rpm

    module.exports = header: 'Epel Prepare', handler: (options) ->
      @file.cache
        if: @contexts('masson/core/epel')[0].config.host is @config.host
        location: true
        md5: options.md5
        sha256: options.sha256
        source: options.url
