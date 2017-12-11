
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java Prepare'
      if: (options) -> options.prepare
      ssh: null
      handler: (options) ->
        for version, info of options.jdk.versions
          console.log
            header: "Oracle JDK #{version}"
            location: true
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.jdk_md5
            sha256: info.jdk_sha256
          @file.cache
            header: "Oracle JDK #{version}"
            location: true
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.jdk_md5
            sha256: info.jdk_sha256
          , "#{info.jdk_location}"
          @file.cache
            header: "Oracle JCE #{version}"
            location: true
            headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.jdk_md5
            sha256: info.jce_sha256
          , "#{info.jce_location}"

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
