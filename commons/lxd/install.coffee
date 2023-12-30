
import yaml from 'js-yaml'

export default
  metadata:
    header: 'LXD Install'
  handler: ({options}) ->
    @system.group header: 'Group', options.group
    @system.user header: 'User', options.user
    @service header: 'Packages', ['lxd', 'zfsutils-linux']
    @system.execute (
      cmd: "#{member}"
    ) for member in options.members
    @system.execute
      cmd: """
      cat <<EOF | lxd init --preseed
      #{yaml.safeDump options.init}
      EOF
      """
