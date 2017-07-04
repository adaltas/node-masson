
# FSTAB Install

    module.exports = header: 'FSTAB Install', handler: (options) ->

## Prepare Disks
Format disks and update the fstab.volumes variables with devices names

      @call
        header: 'Prepare Disk'
      , ->
        @each options.volumes, (opts, callback) ->
          mntpt = opts.key
          disk = opts.value
          return callback null, false unless disk.format
          @system.execute
            header: 'Format Disk'
            if_exec: "file -s #{disk.name} | egrep '^\/dev\/#{path.basename disk.name}:\\sdata$'"
            cmd: "echo 'y\n' | mkfs -t #{disk.type} #{disk.name} \n"
          @system.execute
            cmd: "blkid | sed -n '/#{path.basename disk.name}/s/.*UUID=\\\"\\\([^\\\"]*\\)\\\".*/\\1/p'"
            shy: true
          , (err, _, stdout, __) ->
            return callback err if err
            uuid = stdout.trim()
            disk.device ?= "UUID=#{uuid}"
          @system.mkdir
            target: mntpt
            user: disk.user
            group: disk.user
            mode: disk.mode
          @then callback
        
        

## Write fstab & Mount volume

Write /etc/fstab

      @call
        header: 'Write & Mount'
        if: options.enabled
      , ->
        write = for mntpt, disk of options.volumes
          if options.exhaustive
            "#{disk.device}\t#{mntpt}\t#{disk.options}\t#{disk.dump} #{disk.pass}"
          else
            match: new RegExp "^.*[ \\t]+#{regexp.escape mntpt}[ \\t]+.*$"
            replace: "#{disk.device}\t#{mntpt}\t#{disk.type}\t#{disk.options}\t#{disk.dump} #{disk.pass}"
            append: true
        @file
          header: 'Configure fstab'
          target: '/etc/fstab'
          write: write
          backup: true
          eof: true

## Mount

        @system.execute (
          header: 'Mount Volumes'
          if: options.enabled
          cmd: "mount #{disk.device}"
          unless: mntpt in ['none', 'swap'] or /\/(dev|proc|sys).*/.test mntpt
          unless_exec: "mount | grep '#{mntpt} type'"
        ) for mntpt, disk of options.volumes

## Dependencies

    {regexp} = require 'nikita/lib/misc'
    path = require 'path'
