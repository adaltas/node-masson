
# Java

    path = require 'path'
    semver = require 'semver'
    url = require 'url'
    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push require('../core/proxy').configure

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

[Oracle JDK 6]: http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u45-oth-JPR
[Oracle JDK 7]: http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html

    exports.push module.exports.configure = (ctx) ->
      java = ctx.config.java ?= {}
      # ctx.config.java['openjdk-1.7.0'] ?= true
      # ctx.config.java.java_home ?= '/usr/java/default'
      # Shared
      java.java_home ?= '/usr/lib/jvm/java'
      java.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.java.proxy is 'undefined'
      # OpenJDK
      java.openjdk ?= true
      # throw new Error "Configuration property 'java.location' is required." unless java.location
      # throw new Error "Configuration property 'java.version' is required." unless java.version
      # java.version ?= (/\w+-([\w\d]+)-/.exec path.basename java.location)[0]
      # JCE
      ctx.log? "JCE not configured" unless java.jce_local_policy or java.jce_us_export_policy
        

## Install OpenJDK

    exports.push name: 'Java # Install OpenJDK', callback: (ctx, next) ->
      {openjdk} = ctx.config.java
      return next() unless openjdk
      ctx.service
        name: 'java-1.7.0-openjdk-devel'
      , next

## Remove OpenJDK

At this time, it is recommanded to run Hadoop against the Oracle Java JDK. Since RHEL and CentOS 
come with the OpenJDK installed and to avoid any ambiguity, we simply remove the OpenJDK.

    exports.push name: 'Java # Remove OpenJDK', callback: (ctx, next) ->
      {openjdk} = ctx.config.java
      return next() if openjdk
      ctx.execute
        cmd: 'yum list installed | grep openjdk'
        code_skipped: 1
      , (err, installed, stdout, stderr) ->
        return next err if err
        packages = for l in stdout.trim().split('\n') then /(.*?) .*$/.exec(l)?[1] or l
        ctx.execute
          cmd: "yum remove -y #{packages.join ' '}"
          if: installed
        , next

## Install Oracle JDK

For licensing reason, the Oracle Java JDK is not available from a Yum repository. It is the
phyla integrator responsibility to download the jdk manually and reference it 
inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

    exports.push name: 'Java # Install Oracle JDK', timeout: -1, callback: (ctx, next) ->
      {proxy, jdk} = ctx.config.java # location, version
      return next() unless jdk
      ctx.log "Check if java is here and which version it is"
      ctx.execute
        cmd: 'ls -d /usr/java/jdk*'
      , (err, executed, stdout) ->
        return next err if err and err.code isnt 2
        stdout = '' if err
        installed_version = stdout.trim().split('\n').pop()
        if installed_version
          installed_version = /jdk(.*)/.exec(installed_version)[1]
          installed_version = installed_version.replace('_', '').replace('0', '')
          version = jdk.version.replace('_', '').replace('0', '')
          unless semver.gt version, installed_version
            return next null, false
        action = if url.parse(jdk.location).protocol is 'http:' then 'download' else 'upload'
        ctx.log "Java #{action}"
        tmpdir = "/tmp/masson_java_#{Date.now()}"
        destination = "#{tmpdir}/#{path.basename jdk.location}"
        ctx[action]
          source: jdk.location
          proxy: proxy
          destination: "#{destination}"
          binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.log 'Install jdk in /usr/java'
          ctx.execute
            # cmd: "yes | sh /tmp/#{path.basename jdk.location}"
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
            trap_on_error: true
          , (err, executed, stdout) ->
            return next err, true

## Java JCE

The Java Cryptography Extension (JCE) provides a framework and implementation for encryption, 
key generation and key agreement, and Message Authentication Code (MAC) algorithms. JCE 
supplements the Java platform, which already includes interfaces and implementations of 
message digests and digital signatures.

Like for the Oracle Java JDK, for licensing reason, the JCE is not available from a Yum 
repository. It is the phyla integrator responsibility to download the jdk manually and 
reference it inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

    exports.push name: 'Java # Java JCE', timeout: -1, callback: (ctx, next) ->
      {jdk, jce_local_policy, jce_us_export_policy} = ctx.config.java
      return next() unless jce_local_policy or jce_us_export_policy
      return next() unless jdk
      jdk_home = "/usr/java/jdk#{jdk.version}"
      ctx.log "Download jce-6 Security JARs"
      ctx.upload [
        source: jce_local_policy
        destination: "#{jdk_home}/jre/lib/security/local_policy.jar"
        binary: true
        sha1: true
      ,
        source: jce_us_export_policy
        destination: "#{jdk_home}/jre/lib/security/US_export_policy.jar"
        binary: true
        sha1: true
      ], next

    exports.push name: 'Java # Env', timeout: -1, callback: (ctx, next) ->
      {java_home} = ctx.config.java
      ctx.write
        destination: '/etc/profile.d/java.sh'
        mode: 0o644
        content: """
        export JAVA_HOME=#{java_home}
        export PATH=$PATH:#{java_home}/bin
        """
      , next

## Notes

As of sep 2013, jdk7 is supported by Cloudera but not by Hortonworks.
We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/) 




