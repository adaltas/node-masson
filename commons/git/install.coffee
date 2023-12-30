
import { merge } from 'mixme'

export default header: 'Git Install', handler: (options) ->
  # Package
  # Install the git package.
  @service
    header: 'Package'
    name: 'git'
  # Config
  # Deploy the git configuration.
  @call header: 'Config', (options) ->
    @file.ini
      if: options.global
      target: '/etc/gitconfig'
      content: merge {}, options.properties, options.global
      merge: options.merge
      uid: 'root'
      gid: 'root'
    @system.remove
      if: global is false
      target: '/etc/gitconfig'
    @git_config (
      if: !!user.config
      target: user.target
      config: user.config
      uid: user.uid or user.name
      gid: user.gid or user.group
    ) for _, user of options.users
