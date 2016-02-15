
# Java

    exports = module.exports = []
    
    exports.configure = (ctx) ->
      return if ctx['masson/commons/java.configured']
      ctx['masson/commons/java.configured'] = true
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
      # JCE
      java.jdk ?= {}
      java.jdk.version ?= '1.7.0_79'
      java.jdk.location ?= "http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.tar.gz"
      java.jce ?= {}
      java.jce.location ?= "http://download.oracle.com/otn-pub/java/jce/7/UnlimitedJCEPolicyJDK7.zip"

    module.exports.push commands: 'install', modules: 'masson/commons/java/install'

    module.exports.push commands: 'prepare', modules: 'masson/commons/java/prepare'

## Resources

*   [Oracle JDK 6](http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u45-oth-JPR)
*   [Oracle JDK 7](http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html)
      
