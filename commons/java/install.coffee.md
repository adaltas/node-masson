
# Java Install

Install the Oracle Java JRE and JDK. The Java Runtime Environment is the code 
execution component of the Java platform. The Java Development Kit (JDK) is 
an implementation of either one of the Java SE, Java EE or Java ME platforms[1] 
released by Oracle Corporation in the form of a binary product aimed at Java 
developers on Solaris, Linux, Mac OS X or Windows.

TODO: leverage /etc/alternative to switch between multiple JDKs.

    module.exports = header: 'JAVA Install', handler: ->
      {java} = @config
      {java_home} = @config.java
      
      
## Install OpenJDK

      @service
        header: 'Java # Install OpenJDK'
        timeout: -1
        if: -> @config.java.openjdk
        name: 'java-1.7.0-openjdk-devel'

## Remove OpenJDK

At this time, it is recommanded to run Hadoop against the Oracle Java JDK. Since RHEL and CentOS 
come with the OpenJDK installed and to avoid any ambiguity, we simply remove the OpenJDK.

      # @execute
      #   header: 'Java # Remove OpenJDK'
      #   unless: -> @config.java.openjdk
      #   cmd: 'yum -y remove *openjdk*'

## Install Oracle JDK && Java Cryptography Extension

For licensing reason, the Oracle Java JDK is not available from a Yum repository. It is the
phyla integrator responsibility to download the jdk manually and reference it 
inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

The Java Cryptography Extension (JCE) provides a framework and implementation for encryption, 
key generation and key agreement, and Message Authentication Code (MAC) algorithms. JCE 
supplements the Java platform, which already includes interfaces and implementations of 
message digests and digital signatures.

Like for the Oracle Java JDK, for licensing reason, the JCE is not available from a Yum 
repository. It is the phyla integrator responsibility to download the jdk manually and 
reference it inside the configuration. The properties "jce\_local\_policy" and 
"jce\_us\_export_policy" must be modified accordingly with an appropriate location.

Modified status is only needed on the last two copy commands, which means the jars 
have been copied or not (in case they already exist).  

      @call
        header: 'Java Install Oracle JDKs'
        timeout: -1
        if: -> @config.java.jdk
        handler: (options) ->          
          do_install = (version, jdk) =>
            installed_versions = null
            now = Date.now()
            temp_dir = "/tmp/java.#{now}"
            path_name = "#{path.basename jdk.jce_location, '.zip'}"
            @mkdir
              destination: java.root_dir
            @call
              header: "Java JDK Install #{version}"
              handler: ->
                @call 
                  header: "Java JDK Check Installed #{version}"
                  handler: (options, callback) ->
                    @execute
                      cmd: "ls -d #{java.root_dir}/*"
                      code_skipped: 2
                    , (err, executed, stdout, stderr) ->
                      return callback err if err
                      stdout = '' if err or not executed
                      installed_versions = (string.lines stdout.trim())
                        .filter (out) -> out if /jdk(.*)/.exec out
                        .map (abs) -> "#{path.basename abs}" 
                      return callback null, true if installed_versions.indexOf("jdk#{version}") == -1
                      callback null, false
                @download
                  source: jdk.jdk_location
                  destination: "#{temp_dir}/#{path.basename jdk.jdk_location}"
                  if : -> @status -1
                @mkdir
                  destination: "#{java.root_dir}/jdk#{version}"
                @extract
                  source: "#{temp_dir}/#{path.basename jdk.jdk_location}"
                  destination: "#{java.root_dir}/jdk#{version}"
                  strip: 1
                  if: -> @status -2
                @remove
                  destination: "#{temp_dir}/#{path.basename jdk.jdk_location}"
                  if: -> @status -3
            @call
              header: "Java JCE Install #{version}"
              handler: ->
                @download
                  source: "#{jdk.jce_location}"
                  destination: "/var/tmp/#{path.basename jdk.jce_location}"
                  shy: true
                @mkdir 
                  destination: "/var/tmp/#{path_name}.#{now}"
                  shy: true
                @mkdir 
                  destination: "/var/tmp/#{path_name}"
                  shy: true
                @extract
                  source: "/var/tmp/#{path.basename jdk.jce_location}"
                  destination: "/var/tmp/#{path_name}.#{now}"
                  shy: true
                @execute
                  cmd: "mv  /var/tmp/#{path_name}.#{now}/*/* /var/tmp/#{path_name}/"
                  shy: true
                @copy
                  source: "/var/tmp/#{path_name}/local_policy.jar"
                  destination: "#{java.root_dir}/jdk#{version}/jre/lib/security/local_policy.jar"
                @copy
                  source: "/var/tmp/#{path_name}/US_export_policy.jar"
                  destination: "#{java.root_dir}/jdk#{version}/jre/lib/security/US_export_policy.jar"
          do_install(version, jdk) for version, jdk of @config.java.jdks 
            
## Java Paths

      @execute 
        header: 'Set JDK Version (default)'
        cmd: """
            if [ -L  "#{java.root_dir}/default" ] || [ -e "#{java.root_dir}/default" ] ; 
              then 
                source=`readlink #{java.root_dir}/default`
                if [ "$source" == "#{java.root_dir}/jdk#{java.version}" ];
                  then exit 3 ;
                  else
                    rm -f #{java.root_dir}/default;
                    ln -sf #{java.root_dir}/jdk#{java.version} #{java.root_dir}/default;
                    exit 0;
                fi;
              else
                rm -f #{java.root_dir}/default
                ln -sf #{java.root_dir}/jdk#{java.version} #{java.root_dir}/default;
                exit 0;
            fi;
          """
        code_skipped: 3
        trap: true
      @execute 
        header: 'Set JDK Version (latest)'
        cmd: """
            if [ -L  "#{java.root_dir}/latest" ] || [ -e "#{java.root_dir}/latest" ] ; 
              then 
                source=`readlink #{java.root_dir}/latest`
                if [ "$source" == "#{java.root_dir}/jdk#{java.version}" ];
                  then exit 3;
                  else
                    rm -f #{java.root_dir}/latest;
                    ln -sf #{java.root_dir}/jdk#{java.version} #{java.root_dir}/latest;
                    exit 0;
                fi;
              else
                rm -f #{java.root_dir}/latest;
                ln -sf #{java.root_dir}/jdk#{java.version} #{java.root_dir}/latest;
                exit 0;
            fi;
          """
        code_skipped: 3
        trap: true
      @execute 
        header: 'Link Java home'
        unless: java_home is "#{java.root_dir}/default"
        cmd: """
            if [ -L  "#{java_home}" ] || [ -e "#{java_home}" ] ; 
              then 
                source=`readlink #{java_home}`
                if [ "$source" == "#{java_home}" ];
                  then exit 3;
                  else
                    rm -f #{java_home};
                    ln -sf #{java.root_dir}/default #{java_home};
                    exit 0;
                fi;
              else
                rm -f #{java_home};
                ln -sf #{java.root_dir}/default #{java_home};
                exit 0;
            fi;
          """
        code_skipped: 3
        trap: true
      @write
        header: 'Java Env'
        timeout: -1
        destination: '/etc/profile.d/java.sh'
        mode: 0o0644
        content: """
        export JAVA_HOME=#{java_home}
        export PATH=#{java_home}/bin:$PATH
        """

## Dependencies

    path = require 'path'
    semver = require 'semver'
    string = require 'mecano/lib/misc/string'
    

## Notes

We do not attempt to remve GCJ because it is a requirement of the "mysql-connector-java"
and removing the GCJ package also remove the MySQL connector package.

## Resources

*   [Instructions to install Oracle JDK with alternative](http://www.if-not-true-then-false.com/2010/install-sun-oracle-java-jdk-jre-6-on-fedora-centos-red-hat-rhel/) 
