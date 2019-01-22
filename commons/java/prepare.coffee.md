
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java Prepare'
      ssh: false
      handler: ({options}) ->
        return unless options.prepare
        for version, info of options.jdk.versions
          @file.cache
            header: "Oracle JDK #{version}"
            location: true
            http_headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.jdk_md5
            sha256: info.jdk_sha256
          , "#{info.jdk_location}"
          @file.cache
            header: "Oracle JCE #{version}"
            location: true
            http_headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            md5: info.jdk_md5
            sha256: info.jce_sha256
          , "#{info.jce_location}"

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
