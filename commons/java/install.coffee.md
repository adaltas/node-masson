
# Java

    exports = module.exports = []
    exports.push 'masson/bootstrap'

Install the Oracle Java JRE and JDK. The Java Runtime Environment is the code 
execution component of the Java platform. The Java Development Kit (JDK) is 
an implementation of either one of the Java SE, Java EE or Java ME platforms[1] 
released by Oracle Corporation in the form of a binary product aimed at Java 
developers on Solaris, Linux, Mac OS X or Windows.

```json
{
  "java": {
    "java_home": "/usr/java/default",
    "jdk": {
      "version": "1.7.0_60",
      "location": "./resources/jdk-7u60-linux-x64.tar.gz"
    },
    "open_jdk": false,
    "oracle_jdk": "./resources/jdk-6u45-linux-x64-rpm.bin"
    "jce_local_policy": "./resources/jce_policy-7/local_policy.jar"
    "jce_us_export_policy": "./resources/jce_policy-7/US_export_policy.jar"
  }
}
```

TODO: leverage /etc/alternative to switch between multiple JDKs.

## Install OpenJDK

    exports.push
      header: 'Java # Install OpenJDK'
      timeout: -1
      if: -> @config.java.openjdk
      handler: ->
        @service
          name: 'java-1.7.0-openjdk-devel'

## Remove OpenJDK

At this time, it is recommanded to run Hadoop against the Oracle Java JDK. Since RHEL and CentOS 
come with the OpenJDK installed and to avoid any ambiguity, we simply remove the OpenJDK.

    exports.push
      header: 'Java # Remove OpenJDK'
      not_if: -> @config.java.openjdk
      handler: ->
        @execute
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

    exports.push
      header: 'Java # Install Oracle JDK'
      timeout: -1
      if: -> @config.java.jdk
      handler: (options) ->
        {proxy, jdk} = @config.java # location, version
        options.log "Check if java is here and which version it is"
        installed = false
        @execute
          cmd: 'ls -d /usr/java/jdk*'
          if_exec: '[[ -d /usr/java/ ]]'
        , (err, executed, stdout, stderr) ->
          throw err if err and err.code isnt 2
          stdout = '' if err or not executed
          installed_version = stdout.trim().split('\n').pop()
          return unless installed_version
          installed_version = /jdk(.*)/.exec(installed_version)[1]
          installed_version = installed_version.replace('_', '').replace('0', '')
          version = jdk.version.replace('_', '').replace('0', '')
          installed = true unless semver.gt version, installed_version
        tmpdir = "/tmp/masson_java_#{Date.now()}"
        destination = "#{tmpdir}/#{path.basename jdk.location}"
        @download
          source: jdk.location
          proxy: proxy
          destination: "#{destination}"
          binary: true
          not_if: -> installed
        @execute
          cmd: """
          mkdir -p /usr/java
          tar xzf #{destination} -C #{tmpdir}
          rm -rf #{destination}
          version=`ls #{tmpdir}`
          mv #{tmpdir}/$version /usr/java
          ln -sf /usr/java/${version} /usr/java/latest
          ln -sf /usr/java/$version /usr/java/default
          rm -rf #{tmpdir}
          """
          not_if: -> installed
          trap_on_error: true

## Java JCE

The Java Cryptography Extension (JCE) provides a framework and implementation for encryption, 
key generation and key agreement, and Message Authentication Code (MAC) algorithms. JCE 
supplements the Java platform, which already includes interfaces and implementations of 
message digests and digital signatures.

Like for the Oracle Java JDK, for licensing reason, the JCE is not available from a Yum 
repository. It is the phyla integrator responsibility to download the jdk manually and 
reference it inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

    exports.push
      header: 'Java # Java JCE'
      timeout: -1
      if: [
        -> @config.java.jce_local_policy or @config.java.jce_us_export_policy
        -> @config.java.jdk
      ]
      handler: (options) ->
        {jdk, jce_local_policy, jce_us_export_policy} = @config.java
        jdk_home = "/usr/java/jdk#{jdk.version}"
        options.log "Download jce-6 Security JARs"
        @download
          source: jce_local_policy
          destination: "#{jdk_home}/jre/lib/security/local_policy.jar"
          binary: true
          # sha1: true
        @download
          source: jce_us_export_policy
          destination: "#{jdk_home}/jre/lib/security/US_export_policy.jar"
          binary: true
          # sha1: true

## Java # Env

    exports.push header: 'Java # Env', timeout: -1, handler: ->
      {java_home} = @config.java
      @write
        destination: '/etc/profile.d/java.sh'
        mode: 0o0644
        content: """
        export JAVA_HOME=#{java_home}
        export PATH=#{java_home}/bin:$PATH
        """

## Dependencies

    path = require 'path'
    semver = require 'semver'
    url = require 'url'

## Notes

We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/) 
