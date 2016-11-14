
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java # Oracle JDK'
      timeout: -1
      if: -> @contexts('masson/commons/java')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          location: true
          headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
        , ([
          "#{urls.jdk_location}"
          "#{urls.jce_location}"
        ]) for version, urls of java.jdk.versions

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
