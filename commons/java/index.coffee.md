
# Java

* Install openjdk
* Install multiple versions of Oracle JDK
* Install JCE extension for each Oracle JDK
* Set JAVA_HOME in the system profile

    module.exports =
      configure:
        'masson/commons/java/configure'
      commands:
        'prepare': ->
          options = @config.java
          @call 'masson/commons/java/prepare', options
        'install': ->
          options = @config.java
          @call 'masson/commons/java/install', options

## Resources

*   [Oracle JDK 6](http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u45-oth-JPR)
*   [Oracle JDK 7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html)
