
# Java

    exports = module.exports = []
    
    exports.configure = (ctx) ->
      require('../../core/proxy').configure ctx
      java = ctx.config.java ?= {}
      # ctx.config.java['openjdk-1.7.0'] ?= true
      # ctx.config.java.java_home ?= '/usr/java/default'
      # Shared
      java.java_home ?= '/usr/lib/jvm/java'
      java.jre_home ?= '/usr/lib/jvm/java/jre'
      java.proxy = ctx.config.proxy.http_proxy if typeof ctx.config.java.proxy is 'undefined'
      # OpenJDK
      java.openjdk ?= true
      # throw new Error "Configuration property 'java.location' is required." unless java.location
      # throw new Error "Configuration property 'java.version' is required." unless java.version
      # java.version ?= (/\w+-([\w\d]+)-/.exec path.basename java.location)[0]
      # JCE
      # ctx.log? 'JCE not configured' unless java.jce_local_policy or java.jce_us_export_policy

    module.exports.push commands: 'install', modules: 'masson/commons/java/install'

    module.exports.push commands: 'prepare', modules: 'masson/commons/java/prepare'


## Resources


*   [Oracle JDK 6](http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u45-oth-JPR)
*   [Oracle JDK 7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html)
      
