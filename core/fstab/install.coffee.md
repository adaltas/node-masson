
# FSTAB Install

    module.exports = header: 'FSTAB Install', handler: ->
      {fstab} = @config

## Configure

Write /etc/fstab

      write = for mntpt, disk of fstab.volumes
        if fstab.exhaustive
          "#{disk.device}\t#{mntpt}\t#{disk.options}\t#{disk.dump} #{disk.pass}"
        else
          match: new RegExp "^.*[ \\t]+#{regexp.escape mntpt}[ \\t]+.*$"
          replace: "#{disk.device}\t#{mntpt}\t#{disk.type}\t#{disk.options}\t#{disk.dump} #{disk.pass}"
          append: true
      @file
        header: 'Configure'
        target: '/etc/fstab'
        write: write
        backup: true
        eof: true
        if: fstab.enabled

## Mount

      @execute (
        header: 'FSTAB # Mount Volumes'
        if: fstab.enabled
        cmd: "mount #{disk.device}"
        unless: mntpt in ['none', 'swap'] or /\/(dev|proc|sys).*/.test mntpt
        unless_exec: "mount | grep '#{mntpt} type'"
      ) for mntpt, disk of fstab.volumes

## Dependencies

    {regexp} = require 'mecano/lib/misc'
