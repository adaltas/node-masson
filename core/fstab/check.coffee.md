
# FSTAB Check

Checks fstab and mounted points.

    module.exports = header: 'FSTAB Check', label_true: 'CHECKED', handler: (options) ->
      {fstab} = @config
      for mntpt, disk of fstab.volumes
        @system.execute
          header: 'Mountpoints'
          cmd: "[ `df -kP \"#{mntpt}\" | tail -n +2 | awk '{print $NF}'` = \"#{mntpt}\" ]"
          # check if it is a 'true' fs
          unless: /(swap|\/(dev|proc|sys).*)/.test mntpt
