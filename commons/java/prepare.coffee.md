
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java Oracle JDK'
      timeout: -1
      if: -> @contexts('masson/commons/java')[0]?.config.host is @config.host
      handler: ->
        {java} = @config
        for _, jdk of java.jdks
          @cache
            ssh: null
            if: jdk.jdk_location?
            source: "#{jdk.jdk_location}"
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            location: true
          @cache
            ssh: null
            if: jdk.jce_location?
            source: "#{jdk.jce_location}"
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            location: true

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
