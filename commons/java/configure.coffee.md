
# Java Configure

Open JDK require the "java-1.7.0-openjdk-devel" package or Java will default
to gij.

Java home:

*  Open JDK or gij: "/usr/lib/jvm/java"
*  Oracle JDK: "/usr/java/default"

Example for using Oracle JDK:

```
  java:
    java_home: '/usr/java/default/'
    jre_home: '/usr/java/default/jre'
    openjdk: true
    jdk:
      version: '1.7.0_79'
      versions:
        '1.7.0_79':
          jce_location: "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
          jdk_location: "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
        '1.8.0_101':
          jce_location: "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
          jdk_location: "http://download.oracle.com/otn-pub/java/jdk/8u101-b14/jdk-8u101-linux-x64.tar.gz"
```

    module.exports = handler: ->
      java = @config.java ?= {}
      # OpenJDK
      java.openjdk ?= true
      # Oracle JDK
      java.jdk ?= {}
      java.jdk.root_dir ?= '/usr/java'
      java.jdk.version ?= '1.8.0_101'
      java.jdk.location ?= "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
      java.jdk.versions ?= {}
      java.jdk.versions['1.7.0_79'] ?= {}
      java.jdk.versions['1.7.0_79'].jce_location ?= "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
      java.jdk.versions['1.7.0_79'].jdk_location ?= "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
      java.jdk.versions['1.8.0_101'] ?= {}
      java.jdk.versions['1.8.0_101'].jdk_location ?= "http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.tar.gz"
      java.jdk.versions['1.8.0_101'].jce_location ?= "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
      # Java properties
      java.java_home ?= "#{java.jdk.root_dir}/default"
      java.java_home = java.java_home.replace /\/+$/, "" # remove trailing slashes
      java.jre_home ?= "#{java.java_home}/jre"
      java.jre_home = java.jre_home.replace /\/+$/, "" # remove trailing slashes
