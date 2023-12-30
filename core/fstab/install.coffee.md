
# FSTAB Install

    export default header: 'FSTAB Install', handler: ({options}) ->

## Prepare Logical Volumes
Create Logical volume and format partition (before they are mounted by fstab)

      @call
        header: 'Logical Volumes'
      , ->
        @each options.logical_volumes, ({options}, callback) ->
          lvname = options.key
          lv = options.value
          @system.execute
            header: 'Create'
            cmd: """
              lvcreate -L #{lv.size} #{lv.vg_path} -n #{lvname}
            """
            unless_exec: "lvdisplay #{lvname}"
          @system.execute
            header: 'Format'
            if: lv.format
            cmd: "echo 'y\n' | mkfs -t #{lv.type} #{lvname} \n"
            code_skipped: 1
          @system.mkdir
            header: 'Create target'
            target: lv.target
            user: 'root'
            group: 'root'
            mode: 0o0644
          @next callback

## Format Volumes

Format volumes and update the fstab.volumes variables with devices names.

      @call
        header: 'Format Volumes'
      , ->
        @each options.volumes, ({options}, callback) ->
          mntpt = options.key
          disk = options.value
          @call
            if: disk.format
          , ->
            @system.execute
              header: 'Format Disk'
              if_exec: "file -s #{disk.name} | egrep '^\/dev\/#{path.basename disk.name}:\\sdata$'"
              cmd: "echo 'y\n' | mkfs -t #{disk.type} #{disk.name} \n"
            @system.execute
              cmd: "blkid | sed -n '/#{path.basename disk.name}/s/.*UUID=\\\"\\\([^\\\"]*\\)\\\".*/\\1/p'"
              shy: true
              unless: disk.device?
            , (err, obj) ->
              return callback err if err
              uuid = obj.stdout.trim()
              disk.device ?= "UUID=#{uuid}"
          @system.mkdir
            if: disk.options.indexOf('bind') isnt -1
            target: disk.device
            user: disk.user
            group: disk.user
            mode: disk.mode
          @system.mkdir
            target: mntpt
            user: disk.user
            group: disk.user
            mode: disk.mode
          @next callback        
        
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

    {regexp} = require '@nikitajs/core/lib/misc'
    path = require 'path'
