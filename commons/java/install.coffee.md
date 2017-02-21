
# Java Install

Install the Oracle Java JRE and JDK. The Java Runtime Environment is the code
execution component of the Java platform. The Java Development Kit (JDK) is
an implementation of either one of the Java SE, Java EE or Java ME platforms[1]
released by Oracle Corporation in the form of a binary product aimed at Java
developers on Solaris, Linux, Mac OS X or Windows.

TODO: leverage /etc/alternative to switch between multiple JDKs.

    module.exports = header: 'JAVA Install', handler: ->
      {java} = @config
      
## Install OpenJDK

      @service
        header: 'OpenJDK'
        timeout: -1
        if: -> @config.java.openjdk
        name: 'java-1.7.0-openjdk-devel'

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
        timeout: -1
        if: -> @config.java.jdk
      , (options) ->
        installed_versions = null
        @execute
          header: "List Installed JDK"
          cmd: "ls -d #{java.jdk.root_dir}/*"
          code_skipped: 2
          shy: true
        , (err, executed, stdout, stderr) ->
          return callback err if err
          stdout = '' if err or not executed
          installed_versions = (string.lines stdout.trim())
            .filter (out) -> out if /jdk(.*)/.exec out
            .map (abs) -> "#{path.basename abs}" 
        @system.mkdir java.jdk.root_dir
        @each java.jdk.versions, (options, callback) ->
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
            @system.mkdir "#{java.jdk.root_dir}/jdk#{version}"
            @extract
              source: "/tmp/java.#{now}/#{path.basename jdk.jdk_location}"
              target: "#{java.jdk.root_dir}/jdk#{version}"
              strip: 1
            @remove "/tmp/java.#{now}/#{path.basename jdk.jdk_location}"
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
            @extract
              source: "/var/tmp/#{path.basename jdk.jce_location}"
              target: "/tmp/#{path_name}.#{now}"
              shy: true
            @execute
              cmd: "mv  /tmp/#{path_name}.#{now}/*/* /tmp/#{path_name}/"
              shy: true
            @system.copy
              source: "/tmp/#{path_name}/local_policy.jar"
              target: "#{java.jdk.root_dir}/jdk#{version}/jre/lib/security/local_policy.jar"
            @system.copy
              source: "/tmp/#{path_name}/US_export_policy.jar"
              target: "#{java.jdk.root_dir}/jdk#{version}/jre/lib/security/US_export_policy.jar"
            @remove "/tmp/#{path_name}", shy: true
          @then callback
            
## Java Paths

      @execute 
        header: 'Set JDK Version (default)'
        cmd: """
        if [ -L  "#{java.jdk.root_dir}/default" ] || [ -e "#{java.jdk.root_dir}/default" ] ; then 
          source=`readlink #{java.jdk.root_dir}/default`
          if [ "$source" == "#{java.jdk.root_dir}/jdk#{java.jdk.version}" ]; then
            exit 3
          else
            rm -f #{java.jdk.root_dir}/default
            ln -sf #{java.jdk.root_dir}/jdk#{java.jdk.version} #{java.jdk.root_dir}/default
            exit 0
          fi
        else
          rm -f #{java.jdk.root_dir}/default
          ln -sf #{java.jdk.root_dir}/jdk#{java.jdk.version} #{java.jdk.root_dir}/default
          exit 0
        fi
        """
        code_skipped: 3
        trap: true
      @execute 
        header: 'Set JDK Version (latest)'
        cmd: """
        if [ -L  "#{java.jdk.root_dir}/latest" ] || [ -e "#{java.jdk.root_dir}/latest" ] ; then
          source=`readlink #{java.jdk.root_dir}/latest`
          if [ "$source" == "#{java.jdk.root_dir}/jdk#{java.jdk.version}" ]; then
            exit 3
          else
            rm -f #{java.jdk.root_dir}/latest
            ln -sf #{java.jdk.root_dir}/jdk#{java.jdk.version} #{java.jdk.root_dir}/latest
            exit 0
          fi
        else
          rm -f #{java.jdk.root_dir}/latest
          ln -sf #{java.jdk.root_dir}/jdk#{java.jdk.version} #{java.jdk.root_dir}/latest
          exit 0
        fi
        """
        code_skipped: 3
        trap: true
      @execute 
        header: 'Link Java home'
        unless: java.java_home is "#{java.jdk.root_dir}/default"
        cmd: """
        if [ -L  "#{java.java_home}" ] || [ -e "#{java.java_home}" ] ; then
          source=`readlink #{java.java_home}`
          if [ "$source" == "#{java.java_home}" ]; then
            exit 3
          else
            rm -f #{java.java_home}
            ln -sf #{java.jdk.root_dir}/default #{java.java_home}
            exit 0
          fi
        else
          rm -f #{java.java_home}
          ln -sf #{java.jdk.root_dir}/default #{java.java_home}
          exit 0
        fi
        """
        code_skipped: 3
        trap: true
      @file
        header: 'Java Env'
        timeout: -1
        target: '/etc/profile.d/java.sh'
        mode: 0o0644
        content: """
        export JAVA_HOME=#{java.java_home}
        export PATH=#{java.java_home}/bin:$PATH
        """

## Dependencies

    each = require 'each'
    path = require 'path'
    semver = require 'semver'
    string = require 'mecano/lib/misc/string'
    

## Notes

We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/) 
