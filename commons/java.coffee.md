---
title: Java
module: masson/commons/java
layout: module
---

# Java

    path = require 'path'
    semver = require 'semver'
    url = require 'url'
    module.exports = []
    module.exports.push 'masson/bootstrap/'

Install the Oracle Java JRE and JDK. The Java Runtime Environment is the code 
execution component of the Java platform. The Java Development Kit (JDK) is 
an implementation of either one of the Java SE, Java EE or Java ME platforms[1] 
released by Oracle Corporation in the form of a binary product aimed at Java 
developers on Solaris, Linux, Mac OS X or Windows.

    module.exports.push module.exports.configure = (ctx) ->
      require('../core/proxy').configure ctx
      ctx.config.java ?= {}
      ctx.config.java.java_home ?= '/usr/java/default'
      ctx.config.java.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.java is 'undefined'
      throw new Error "Configuration property 'java.location' is required." unless ctx.config.java.location
      throw new Error "Configuration property 'java.version' is required." unless ctx.config.java.version
      # ctx.config.java.version ?= (/\w+-([\w\d]+)-/.exec path.basename ctx.config.java.location)[0]

## Remove OpenJDK

At this time, it is recommanded to run Hadoop against the Oracle Java JDK. Since RHEL and CentOS 
come with the OpenJDK installed and to avoid any ambiguity, we simply remove the OpenJDK.

    module.exports.push name: 'Java # Remove OpenJDK', callback: (ctx, next) ->
      ctx.execute
        cmd: 'yum list installed | grep openjdk'
        code_skipped: 1
      , (err, installed, stdout, stderr) ->
        return next err, ctx.PASS if err or not installed
        packages = for l in stdout.trim().split('\n') then /(.*?) .*$/.exec(l)?[1] or l
        ctx.execute
          cmd: "yum remove -y #{packages.join ' '}"
        , (err) ->
          next err, ctx.OK

## Install

For licensing reason, the Oracle Java JDK is not available from a Yum repository. It is the
phyla integrator responsibility to download the jdk manually and reference it 
inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

    module.exports.push name: 'Java # Install', timeout: -1, callback: (ctx, next) ->
      {proxy, location, version} = ctx.config.java
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
          version = version.replace('_', '').replace('0', '')
          unless semver.gt version, installed_version
            return next null, ctx.PASS
        action = if url.parse(location).protocol is 'http:' then 'download' else 'upload'
        ctx.log "Java #{action}"
        ctx[action]
          source: location
          proxy: proxy
          destination: "/tmp/#{path.basename location}"
          binary: true
        , (err, downloaded) ->
          return next err if err
          ctx.log 'Install jdk in /usr/java'
          ctx.execute
            cmd: "yes | sh /tmp/#{path.basename location}"
          , (err, executed) ->
            return next err if err
            ctx.remove
              destination: "/tmp/#{path.basename location}"
            , (err, executed) ->
              next err, ctx.OK

##Java JCE

The Java Cryptography Extension (JCE) provides a framework and implementation for encryption, 
key generation and key agreement, and Message Authentication Code (MAC) algorithms. JCE 
supplements the Java platform, which already includes interfaces and implementations of 
message digests and digital signatures.

Like for the Oracle Java JDK, for licensing reason, the JCE is not available from a Yum 
repository. It is the phyla integrator responsibility to download the jdk manually and 
reference it inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

    module.exports.push name: 'Java # Java JCE', timeout: -1, callback: (ctx, next) ->
      {java_home, jce_local_policy, jce_us_export_policy} = ctx.config.java
      return next Error "JCE not configured" unless jce_local_policy or jce_us_export_policy
      ctx.log "Download jce-6 Security JARs"
      ctx.upload [
        source: jce_local_policy
        destination: "#{java_home}/jre/lib/security/local_policy.jar"
        binary: true
        sha1: 'c557a5da9075f41ede10829e9ff562b132b3246d'
      ,
        source: jce_us_export_policy
        destination: "#{java_home}/jre/lib/security/US_export_policy.jar"
        binary: true
        sha1: '1b5eb80bd3699de9b668d5f7b1a1d89681a91190'
      ], (err, downloaded) ->
        next err, if downloaded then ctx.OK else ctx.PASS

    module.exports.push name: 'Java # Env', timeout: -1, callback: (ctx, next) ->
      ctx.write
        destination: '/etc/profile.d/java.sh'
        mode: 644
        content: """
        export JAVA_HOME=/usr/java/default
        export PATH=$PATH:/usr/java/default/bin
        """
      , (err, written) ->
        next err, if written then ctx.OK else ctx.PASS

## Notes

As of sep 2013, jdk7 is supported by Cloudera but not by Hortonworks.
We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/) 




