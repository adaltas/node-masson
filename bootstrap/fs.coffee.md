
# Bootstrap FS

Enrich the server context with [File System][nodefs] functions.

## File System

File System functionnalities are imported from the [Node.js `fs`][nodefs] API with
transparent SSH2 transport thanks to the [ssh2-fs] package.

    module.exports = ->
      @fs = {}
      [ 'rename', 'chown', 'chmod', 'stat', 'lstat', 'unlink', 'symlink',
        'readlink', 'unlink', 'mkdir', 'readdir', 'readFile', 'writeFile',
        'exists', 'createReadStream', 'createWriteStream' ].forEach (fn) =>
        @fs[fn] = =>
          ssh = @ssh options.ssh
          fs[fn].call null, ssh, arguments...

# Dependencies

    fs = require 'ssh2-fs'

[ssh2-fs]: https://github.com/wdavidw/node-ssh2-fs
[nodefs]: http://nodejs.org/api/fs.html
