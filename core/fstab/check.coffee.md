
# FSTAB Check

Checks fstab and mounted points.

    module.exports = header: 'FSTAB Check # Check Mountpoints', label_true: 'CHECKED', handler: ->
      {fstab} = @config
      for mntpt, disk of fstab.volumes
        @execute
          cmd: "[ `df -kP #{mntpt} | tail -n +2 | awk '{print $NF}'` = #{mntpt} ]"
          # check if it is a 'true' fs
          unless: /(swap|\/(dev|proc|sys).*)/.test mntpt
