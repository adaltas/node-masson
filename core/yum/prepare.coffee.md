
# Epel Release Prepare

Download the epel release rpm

    module.exports = header: 'Yum Prepare', handler: (options) ->
      @file.cache
        header: 'Epel'
        if: @contexts('masson/core/yum')[0].config.host is @config.host
        location: true
        md5: options.epel.md5
        sha256: options.epel.sha256
        source: options.epel.url
