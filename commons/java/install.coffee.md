
# Java Install

Install the Oracle Java JRE and JDK. The Java Runtime Environment is the code 
execution component of the Java platform. The Java Development Kit (JDK) is 
an implementation of either one of the Java SE, Java EE or Java ME platforms[1] 
released by Oracle Corporation in the form of a binary product aimed at Java 
developers on Solaris, Linux, Mac OS X or Windows.

TODO: leverage /etc/alternative to switch between multiple JDKs.

    module.exports = header: 'JAVA Install', handler: ->

## Install OpenJDK

      @service
        header: 'Java # Install OpenJDK'
        timeout: -1
        if: -> @config.java.openjdk
        name: 'java-1.7.0-openjdk-devel'

## Remove OpenJDK

At this time, it is recommanded to run Hadoop against the Oracle Java JDK. Since RHEL and CentOS 
come with the OpenJDK installed and to avoid any ambiguity, we simply remove the OpenJDK.

      @execute
        header: 'Java # Remove OpenJDK'
        unless: -> @config.java.openjdk
        cmd: 'yum -y remove *openjdk*'
      # @execute
      #   cmd: 'yum list installed | grep openjdk'
      #   code_skipped: 1
      # , (err, installed, stdout, stderr) ->
      #   return callback err if err
      #   packages = for l in stdout.trim().split('\n') then /(.*?) .*$/.exec(l)?[1] or l
      #   ctx.execute
      #     cmd: "yum remove -y #{packages.join ' '}"
      #     if: installed
      #   , callback

## Install Oracle JDK

For licensing reason, the Oracle Java JDK is not available from a Yum repository. It is the
phyla integrator responsibility to download the jdk manually and reference it 
inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

      @call
        header: 'Java # Install Oracle JDK'
        timeout: -1
        if: -> @config.java.jdk
        handler: (options) ->
          {java} = @config
          options.log "Check if java is here and which version it is"
          # installed = false
          @mkdir
            destination: '/usr/java'
          @execute
            shy: true
            cmd: 'ls -d /usr/java/jdk*'
            # if_exec: '[[ -d /usr/java/ ]]'
            code_skipped: 2
          , (err, executed, stdout, stderr) ->
            throw err if err #and err.code isnt 2
            stdout = '' if err or not executed
            installed_version = stdout.trim().split('\n').pop()
            return unless installed_version
            installed_version = /jdk(.*)/.exec(installed_version)[1]
            installed_version = installed_version.replace('_', '').replace('0', '')
            version = java.jdk.version.replace('_', '').replace('0', '')
            installed = true unless semver.gt version, installed_version
            @end() if installed
          @download
            source: "#{java.jdk.location}"
            destination: "/var/tmp/#{path.basename java.jdk.location}"
          @execute
            cmd: """
            rand=$RANDOM
            mkdir -p /tmp/ryba-${rand}
            tar xzf /var/tmp/#{path.basename java.jdk.location} -C /tmp/ryba-${rand}
            version=`ls /tmp/ryba-${rand}`
            mv /tmp/ryba-${rand}/$version /usr/java
            ln -sf /usr/java/${version} /usr/java/latest
            ln -sf /usr/java/$version /usr/java/default
            rm -rf /tmp/ryba-${rand}
            """
            trap: true

## Java JCE

The Java Cryptography Extension (JCE) provides a framework and implementation for encryption, 
key generation and key agreement, and Message Authentication Code (MAC) algorithms. JCE 
supplements the Java platform, which already includes interfaces and implementations of 
message digests and digital signatures.

Like for the Oracle Java JDK, for licensing reason, the JCE is not available from a Yum 
repository. It is the phyla integrator responsibility to download the jdk manually and 
reference it inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

      @call
        header: 'Java # Java JCE'
        timeout: -1
        if: [
          -> @config.java.jce.location
          -> @config.java.jdk
        ]
        handler: (options) ->
          {java} = @config
          jdk_home = "/usr/java/jdk#{java.jdk.version}"
          @download
            source: "#{java.jce.location}"
            destination: "/var/tmp/#{path.basename java.jce.location}"
          @extract
            source: "/var/tmp/#{path.basename java.jce.location}"
            destination: "/var/tmp/#{path.basename java.jce.location, '.zip'}"
            if: -> @status -1
          @copy
            source: "/var/tmp/#{path.basename java.jce.location, '.zip'}/UnlimitedJCEPolicy/local_policy.jar"
            destination: "#{jdk_home}/jre/lib/security/local_policy.jar"
          @copy
            source: "/var/tmp/#{path.basename java.jce.location, '.zip'}/UnlimitedJCEPolicy/US_export_policy.jar"
            destination: "#{jdk_home}/jre/lib/security/US_export_policy.jar"

## Java # Env

      {java_home} = @config.java
      @write
        header: 'Java # Env'
        timeout: -1
        destination: '/etc/profile.d/java.sh'
        mode: 0o0644
        content: """
        export JAVA_HOME=#{java_home}
        export PATH=#{java_home}/bin:$PATH
        """

## Dependencies

    path = require 'path'
    semver = require 'semver'

## Notes

We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/) 
