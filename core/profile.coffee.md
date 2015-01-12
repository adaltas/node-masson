
# Profile

Publish scripts inside the profile directory, located in "/etc/profile.d".

    exports = module.exports = []
    exports.push 'masson/bootstrap'

## Configuration

The module accept the following properties:

*   `profile` (object)   
    Object where keys are the script filename and values are the script
    content.    

Example:

```json
{
  "profile": {
    "tmout.sh": "export TMOUT=0"
  }
}
```

    exports.push (ctx) ->
      ctx.config.profile ?= {}

## Upload

Upload all the configured scripts.

    exports.push name: 'Profile # Upload', callback: (ctx, next) ->
      writes = for filename, content of ctx.config.profile
        destination: "/etc/profile.d/#{filename}"
        content: content
        eof: true
      ctx.write writes, next

## Dependencies

    each = require 'each'
