
# Java Install

Install the Oracle Java JRE and JDK. The Java Runtime Environment is the code
execution component of the Java platform. The Java Development Kit (JDK) is
an implementation of either one of the Java SE, Java EE or Java ME platforms[1]
released by Oracle Corporation in the form of a binary product aimed at Java
developers on Solaris, Linux, Mac OS X or Windows.

TODO: leverage /etc/alternative to switch between multiple JDKs.

    module.exports = header: 'JAVA Install', handler: ({options}) ->
      {root_dir} = options.jdk
      
## Install OpenJDK

      @service
        header: 'OpenJDK'
        if: -> options.openjdk
        name: 'java-1.8.0-openjdk-devel'

## Install Oracle JDK && Java Cryptography Extension

At this time, it is recommanded to run Hadoop against the Oracle Java JDK. Since RHEL and CentOS
come with the OpenJDK installed and to avoid any ambiguity, we simply remove the OpenJDK.

For licensing reason, the Oracle Java JDK is not available from a Yum repository. It is the
integrator responsibility to download the jdk manually and reference it
inside the configuration. The properties "jce\_local\_policy" and
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

The Java Cryptography Extension (JCE) provides a framework and implementation for encryption,
key generation and key agreement, and Message Authentication Code (MAC) algorithms. JCE
supplements the Java platform, which already includes interfaces and implementations of
message digests and digital signatures.

Like for the Oracle Java JDK, for licensing reason, the JCE is not available from a Yum
repository. It is the phyla integrator responsibility to download the jdk manually and
reference it inside the configuration. The properties "jce\_local\_policy" and
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

Modified status is only needed on the last two copy commands, which means the jars
have been copied or not (in case they already exist).

      @call
        header: 'Oracle JDKs'
        if: -> options.jdk
      , ->
        installed_versions = null
        @system.mkdir
          target: root_dir
        @system.execute
          header: "List Installed JDK"
          # Better than ls, it ignores links and empty dirs
          cmd: "find #{root_dir} -mindepth 1 -maxdepth 1 -not -empty -type d"
          # cmd: "ls -d #{root_dir}/*"
          # code_skipped: 2
          shy: true
        , (err, data) ->
          throw err if err
          stdout = '' unless data.status
          installed_versions = (string.lines data.stdout.trim())
            .filter (out) -> out if /jdk(.*)/.exec out
            .map (abs) -> "#{path.basename abs}"
        @system.mkdir root_dir
        @service.install
          header: 'Dependency unzip'
          if: Object.keys(options.jdk.versions).length
          name: 'unzip'
        @each options.jdk.versions, ({options}, callback) ->
          version = options.key
          jdk = options.value
          installed = installed_versions.indexOf("jdk#{version}") isnt -1
          path_name = "#{path.basename jdk.jce_location, '.zip'}"
          now = Date.now()
          @call
            header: "JDK #{version}"
            unless: -> installed
          , ->
            @file.download
              source: jdk.jdk_location
              target: "/tmp/java.#{now}/#{path.basename jdk.jdk_location}"
              location: true
              headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
            @system.mkdir "#{root_dir}/jdk#{version}"
            @tools.extract
              source: "/tmp/java.#{now}/#{path.basename jdk.jdk_location}"
              target: "#{root_dir}/jdk#{version}"
              strip: 1
            @system.remove "/tmp/java.#{now}/#{path.basename jdk.jdk_location}"
          @call
            header: "JCE #{version}"
          , ->
            @file.download
              source: "#{jdk.jce_location}"
              target: "/var/tmp/#{path.basename jdk.jce_location}"
              location: true
              headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
              shy: true
            @system.mkdir "/tmp/#{path_name}.#{now}", shy: true
            @system.mkdir "/tmp/#{path_name}", shy: true
            @tools.extract
              source: "/var/tmp/#{path.basename jdk.jce_location}"
              target: "/tmp/#{path_name}.#{now}"
              shy: true
            @system.execute
              cmd: "mv  /tmp/#{path_name}.#{now}/*/* /tmp/#{path_name}/"
              shy: true
            @system.copy
              source: "/tmp/#{path_name}/local_policy.jar"
              target: "#{root_dir}/jdk#{version}/jre/lib/security/local_policy.jar"
            @system.copy
              source: "/tmp/#{path_name}/US_export_policy.jar"
              target: "#{root_dir}/jdk#{version}/jre/lib/security/US_export_policy.jar"
            @system.remove "/tmp/#{path_name}", shy: true
          @next callback

## Java Paths

      @system.execute
        header: 'Set default JDK'
        cmd: """
        if [ -L  "#{root_dir}/default" ] || [ -e "#{root_dir}/default" ] ; then 
          source=`readlink #{root_dir}/default`
          if [ "$source" == "#{root_dir}/jdk#{options.jdk.version}" ]; then
            exit 3
          else
            rm -f #{root_dir}/default
            ln -sf #{root_dir}/jdk#{options.jdk.version} #{root_dir}/default
            exit 0
          fi
        else
          rm -f #{root_dir}/default
          ln -sf #{root_dir}/jdk#{options.jdk.version} #{root_dir}/default
          exit 0
        fi
        """
        code_skipped: 3
        trap: true
      @system.execute
        header: 'Set latest JDK'
        cmd: """
        if [ -L  "#{root_dir}/latest" ] || [ -e "#{root_dir}/latest" ] ; then
          source=`readlink #{root_dir}/latest`
          if [ "$source" == "#{root_dir}/jdk#{options.jdk.version}" ]; then
            exit 3
          else
            rm -f #{root_dir}/latest
            ln -sf #{root_dir}/jdk#{options.jdk.version} #{root_dir}/latest
            exit 0
          fi
        else
          rm -f #{root_dir}/latest
          ln -sf #{root_dir}/jdk#{options.jdk.version} #{root_dir}/latest
          exit 0
        fi
        """
        code_skipped: 3
        trap: true
      @system.execute
        header: 'Link Java home'
        unless: options.java_home is "#{root_dir}/default"
        cmd: """
        if [ -L  "#{options.java_home}" ] || [ -e "#{options.java_home}" ] ; then
          source=`readlink #{options.java_home}`
          if [ "$source" == "#{options.java_home}" ]; then
            exit 3
          else
            rm -f #{options.java_home}
            ln -sf #{root_dir}/default #{options.java_home}
            exit 0
          fi
        else
          rm -f #{options.java_home}
          ln -sf #{root_dir}/default #{options.java_home}
          exit 0
        fi
        """
        code_skipped: 3
        trap: true
      @file
        header: 'Java Env'
        target: '/etc/profile.d/java.sh'
        mode: 0o0644
        content: """
        export JAVA_HOME=#{options.java_home}
        export PATH=#{options.java_home}/bin:$PATH
        """

## Dependencies

    each = require 'each'
    path = require 'path'
    string = require 'nikita/lib/misc/string'

## Notes

We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/)
