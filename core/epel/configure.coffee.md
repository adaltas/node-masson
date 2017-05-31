
# Epel Configure


Examples

* specify `repo` file without `url`
```json
{
  "epel": {
    "repo": '/home/masson/repos/epel.repo'
  }
}
```

* specify rpm url
```json
{
  "epel": {
    "url": 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
  }
}
```

When url and repo optins are specified, `repo` has the priority.

    module.exports = ->
      options = @config.epel ?= {}
      options.url ?= 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
      options.repo ?= null
      options.url = null if options.repo?
