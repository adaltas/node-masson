
# Java Prepare

Download the Oracle JDK.

    module.exports = []
    module.exports.push 'masson/bootstrap'

## Spark Users And Group

    module.exports.push name: 'Java # Oracle JDK', handler: ->
      @execute
        cmd: """
          wget --no-cookies \
          --no-check-certificate \
          --header "Cookie: oraclelicense=accept-securebackup-cookie" \
          "http://download.oracle.com/otn-pub/java/jdk/7u55-b13/jdk-7u55-linux-x64.rpm" \
          -O jdk-7-linux-x64.rpm
          """

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
