
# Check FSTAB

checks fstab and mounted points

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Check mounted points

    exports.push header: 'FSTAB # Check Mountpoints', handler: ->
      {fstab} = @config
      for mntpt, disk of fstab.volumes
        @execute 
          cmd: "[ `df -kP #{mntpt} | tail -n +2 | awk '{print $NF}'` = #{mntpt} ]"
          unless: mntpt in ['none', 'swap'] or /\/(dev|proc|sys).*/.test mntpt

