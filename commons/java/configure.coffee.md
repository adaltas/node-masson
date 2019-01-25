
# Java Configure

## Options

* `java_home` (string)   
* `jre_home` (string)   
* `openjdk` (string)   
* `jdk` (object)   
* `jdk.version` (object)   
   Default JDK to use.
* `jdk.versions` (object)   
   Define all the JDKs to install
* `jdk.versions.{version}` (object)   
   Define a JDK to install
* `jdk.versions.{version}.jdk_location` (object)   
   URL or local path to the JDK package (tar.gz, zip shall work as well)
* `jdk.versions.{version}.jce_location` (object)   
   URL or local path to the JCE libraries (zip)

## Notes

Open JDK require the "java-1.8.0-openjdk-devel" package or Java will default
to gij.

Java home are:

*  Open JDK or gij: "/usr/lib/jvm/java"
*  Oracle JDK: "/usr/java/default"

## Example with Oracle JDK:

```json
{ "java": {
    "java_home": "/usr/java/default",
    "jre_home": "/usr/java/default/jre",
    "openjdk": true,
    "jdk": {
      "version": "1.7.0_79",
      "versions": {
        "1.7.0_79": {
          "jdk_location": "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz",
          "jdk_sha256": "29d75d0022bfa211867b876ddd31a271b551fa10727401398295e6e666a11d90",
          "jce_location": "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip",
          "jce_sha256": "7a8d790e7bd9c2f82a83baddfae765797a4a56ea603c9150c87b7cdb7800194d"
        },
        "1.8.0_101": {
          "jdk_location": "http://download.oracle.com/otn-pub/java/jdk/8u121-b14/jdk-8u121-linux-x64.tar.gz",
          "jdk_sha256": "467f323ba38df2b87311a7818bcbf60fe0feb2139c455dfa0e08ba7ed8581328",
          "jce_location": "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip",
          "jce_sha256": "f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59"
        }
      }
    }
}}
```

    module.exports = (service) ->
      options = service.options

## OpenJDK

      options.openjdk ?= false

## Oracle JDK

      options.jdk ?= {}
      options.jdk.root_dir ?= '/usr/java'
      options.jdk.version ?= '1.8.0_152'
      options.jdk.versions ?=
        '1.8.0_152':
          jdk_location: "https://download.oracle.com/otn-pub/java/jdk/8u202-b08/1961070e4c9b4e26a04e7f5a083f551e/jdk-8u202-linux-x64.tar.gz"
          jdk_md5: "20dddd28ced3179685a5f58d3fcbecd8"
          jce_location: "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
          jce_sha256: "f3020a3922efd6626c2fff45695d527f34a8020e938a49292561f18ad1320b59"
      # options.jdk.versions['1.7.0_79'] ?= {}
      # options.jdk.versions['1.7.0_79'].jdk_location ?= "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
      # options.jdk.versions['1.7.0_79'].jdk_sha256 ?= "29d75d0022bfa211867b876ddd31a271b551fa10727401398295e6e666a11d90"
      # options.jdk.versions['1.7.0_79'].jce_location ?= "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"
      # options.jdk.versions['1.7.0_79'].jce_sha256 ?= "7a8d790e7bd9c2f82a83baddfae765797a4a56ea603c9150c87b7cdb7800194d"

## Java properties

      options.java_home ?= "#{options.jdk.root_dir}/default"
      options.java_home = options.java_home.replace /\/+$/, "" # remove trailing slashes
      options.jre_home ?= "#{options.java_home}/jre"
      options.jre_home = options.jre_home.replace /\/+$/, "" # remove trailing slashes

## Command Specific

      # Ensure "prepare" is executed locally only once
      options.prepare = service.node.id is service.instances[0].node.id
