
# Virtual Box

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/curl'

    exports.push header: 'VirtualBox Guest Additions', handler: (options) ->
      version_target, version_current
      @system.execute
        ssh: false
        cmd: 'VBoxManage -v'
      , (err, executed, stdout) ->
        return next err if err
        options.log 'Get Guest Additions version on VM machine'
        version_target = /\d+\.\d+\.\d+/.exec(stdout)[0]
      @call ->
        @system.execute
          cmd: "modinfo vboxguest | grep ^version: | sed -r 's/.* ([0-9\\.]+)/\\1/'"
          code_skipped: 1
        , (err, executed, stdout) ->
          throw err if err
          version_current = stdout.trim()
      @call ->
        options.log "Install latest Guest Additions #{version_target}"
        @system.execute
          cmd: """
            yum install -y gcc kernel-* # might need to reboot
            source="http://download.virtualbox.org/virtualbox/#{version_target}/VBoxGuestAdditions_#{version_target}.iso"
            target="/tmp/VBoxGuestAdditions_#{version_target}.iso"
            curl -L #{source} -o #{target}
            mount #{target} -o loop /mnt
            cd /mnt
            sh VBoxLinuxAdditions.run --nox11
            rm #{target}
            /etc/init.d/vboxadd setup
            chkconfig --add vboxadd
            chkconfig vboxadd on
            umount /mnt
            """
            if: version_current is version_target
        @call
          if: -> @status()
          handler: (_, callback) ->
            @reboot callback
        
