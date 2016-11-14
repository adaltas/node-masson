
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java # Oracle JDK'
      timeout: -1
      if: -> @contexts('masson/commons/java')[0]?.config.host is @config.host
      handler: ->
      {java} = @config
      for version, urls of java.jdk.versions
        @cache
          ssh: null
          location: true
          headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
        , "#{urls.jdk_location}"
        @cache
          ssh: null
          location: true
          headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
        , "#{urls.jce_location}"

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
