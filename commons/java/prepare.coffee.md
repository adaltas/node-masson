
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java Prepare'
      timeout: -1
      if: -> @contexts('masson/commons/java')[0]?.config.host is @config.host
      handler: ->
        {java} = @config
        for version, info of java.jdk.versions
          @file.cache
            header: "Oracle JDK #{version}"
            ssh: null
            location: true
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.md5
            sha256: info.sha256
          , "#{info.jdk_location}"
          @file.cache
            header: "Oracle JCE #{version}"
            ssh: null
            location: true
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.md5
            sha256: info.sha256
          , "#{info.jce_location}"

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
