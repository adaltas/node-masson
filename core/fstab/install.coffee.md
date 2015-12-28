
# Install FSTAB

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configure

Write /etc/fstab

    exports.push header: 'FSTAB # Configure', handler: ->
      {fstab} = @config
      write = for mntpt, disk of fstab.volumes
        if fstab.exhaustive
          "#{disk.device}\t#{mntpt}\t#{disk.options}\t#{disk.dump} #{disk.pass}"
        else
          match: new RegExp "^.*[ \\t]+#{regexp.escape mntpt}[ \\t]+.*$"
          replace: "#{disk.device}\t#{mntpt}\t#{disk.type}\t#{disk.options}\t#{disk.dump} #{disk.pass}"
          append: true
      @write
        destination: '/etc/fstab'
        write: write
        backup: true
        eof: true
        if: fstab.enabled

## Mount

    exports.push header: 'FSTAB # Mount Volumes', handler: ->
      {fstab} = @config
      if fstab.enabled then for mntpt, disk of fstab.volumes
        @execute
          cmd: "mount #{disk.device}"
          unless: mntpt in ['none', 'swap'] or /\/(dev|proc|sys).*/.test mntpt
          unless_exec: "mount | grep '#{mntpt} type'"

## Dependencies

    {regexp} = require 'mecano/lib/misc'
