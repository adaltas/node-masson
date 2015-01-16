
# Virtual Box

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/curl'

    exports.push name: 'VirtualBox # Guest Additions', timeout: -1, handler: (ctx, next) ->
      ctx.execute
        ssh: false
        cmd: 'VBoxManage -v'
      , (err, executed, stdout) ->
        return next err if err
        ctx.log 'Get Guest Additions version on VM machine'
        version = /\d+\.\d+\.\d+/.exec(stdout)[0]
        ctx.execute
          cmd: 'modinfo vboxguest | grep ^version:'
          code_skipped: 1
        , (err, executed, stdout) ->
          return next err if err
          return next null, ctx.PASS if executed and /\d+\.\d+\.\d+/.exec(stdout)[0] is version
          ctx.log "Install latest Guest Additions #{version}"
          source = "http://download.virtualbox.org/virtualbox/#{version}/VBoxGuestAdditions_#{version}.iso"
          destination = "/tmp/VBoxGuestAdditions_#{version}.iso"
          ctx.execute
            cmd: """
              yum install -y gcc kernel-* # might need to reboot
              curl -L #{source} -o #{destination}
              mount #{destination} -o loop /mnt
              cd /mnt
              sh VBoxLinuxAdditions.run --nox11
              rm #{destination}
              /etc/init.d/vboxadd setup
              chkconfig --add vboxadd
              chkconfig vboxadd on
              umount /mnt
              """
          , (err, executed, stdout, stderr) ->
            return next err if err
            ctx.reboot (err) ->
              next err, ctx.OK
        


