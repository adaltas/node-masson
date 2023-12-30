
# FSTAB Check

Checks fstab and mounted points.

    export default header: 'FSTAB Check', handler: ({options}) ->
      for mntpt, disk of options.volumes
        @system.execute
          header: 'Mountpoints'
          cmd: "[ `df -kP \"#{mntpt}\" | tail -n +2 | awk '{print $NF}'` = \"#{mntpt}\" ]"
          # check if it is a 'true' fs
          unless: /(swap|\/(dev|proc|sys).*)/.test mntpt
