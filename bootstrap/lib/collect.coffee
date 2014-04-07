
fs = require 'fs'

module.exports = (config, callback) ->
  username config, ->
    password config, ->
      public_key config, (err) ->
        return callback err if err
        callback()

username = (config, callback) ->
  return callback() if config.username
  process.stdout.write 'username: '
  prompt (username) ->
    config.username = username
    callback()

password = (config, callback) ->
  return callback() if config.password
  process.stdout.write 'Password: '
  promptpass (password) ->
    config.password = password
    callback()

public_key = (config, callback) ->
  return callback() if config.public_key
  process.stdout.write 'Public key (~/.ssh/id_rsa.pub): '
  prompt (path) ->
    path = '~/.ssh/id_rsa.pub' unless path
    path = process.env.HOME + match[1] if match = /~(\/.*)/.exec path
    fs.readFile path, (err, public_key) ->
      return callback err if err
      config.public_key = public_key
      callback()

prompt = (callback) ->
  #https://github.com/substack/node-charm
  process.stdin.resume()
  process.stdin.setEncoding 'utf8'
  process.stdin.setRawMode true  
  value = ''
  process.stdin.on 'data', lst = (char)->
    char = char + ''
    switch char
      when '\n', '\r', '\u0004'
        process.stdin.setRawMode false
        process.stdin.pause()
        process.stdout.write '\n'
        process.stdin.removeListener 'data', lst
        callback value
      when '\u0003' # Ctrl C
        process.exit()
      else
        process.stdout.write char
        value += char
        break

promptpass = (callback) ->
  #https://github.com/substack/node-charm
  process.stdin.resume()
  process.stdin.setEncoding 'utf8'
  process.stdin.setRawMode true  
  value = ''
  process.stdin.on 'data', lst = (char)->
    char = char + ''
    switch char
      when '\n', '\r', '\u0004'
        # They've finished typing their password
        process.stdin.setRawMode false
        process.stdin.pause()
        process.stdout.write '\n'
        process.stdin.removeListener 'data', lst
        callback value
      when '\u0003' # Ctrl C
        process.exit()
      else
        # More passsword characters
        process.stdout.write '*'
        value += char
        break


