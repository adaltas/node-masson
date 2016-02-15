
# Java Prepare

Download the Oracle JDK.

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Spark Users And Group

    module.exports.push
      header: 'Java # Oracle JDK'
      timeout: -1
      if: -> @contexts('masson/commons/java')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: "#{java.jdk.location}"
          headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
          location: true
        @cache
          ssh: null
          source: "#{java.jce.location}"
          headers: ['Cookie: oraclelicense=accept-securebackup-cookie']
          location: true

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
