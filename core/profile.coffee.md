
# Profile

Publish scripts inside the profile directory, located in "/etc/profile.d".

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

    module.exports = (ctx) ->
      @config.profile ?= {}
      'install': header: 'Profile Install', handler: ->

## Upload

Upload all the configured scripts.
        
        @write (
          header: 'Upload'
          target: "/etc/profile.d/#{filename}"
          content: content
          eof: true
        ) for filename, content of @config.profile
