
# Java Configure

Open JDK require the "java-1.7.0-openjdk-devel" package or Java will default
to gij.

Java home:

*  Open JDK or gij: "/usr/lib/jvm/java"
*  Oracle JDK: "/usr/java/default"

Example for using Oracle JDK:

```
{ 
  "java": {
    "java_home": "/usr/java/default/",
    "jre_home": "/usr/java/default/jre",
    "openjdk": true,
    "jdk": {
      "version": "1.7.0_79",
      "location": "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gzz"
    },
    "jce": "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
}}
```

    module.exports = handler: ->
      @config.java ?= {}
      # Shared
      @config.java.java_home ?= '/usr/lib/jvm/java'
      @config.java.jre_home ?= '/usr/lib/jvm/java/jre'
      # OpenJDK
      @config.java.openjdk ?= true
      # JCE
      @config.java.jdk ?= {}
      @config.java.jdk.version ?= '1.7.0_79'
      @config.java.jdk.location ?= "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
      @config.java.jce ?= {}
      @config.java.jce.location ?= "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
