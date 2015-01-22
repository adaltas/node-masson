
# Backup a directory into another directory

```
var backmeup = require('backmeup');
backmeup({
  source: '/etc'
  destination: '/tmp'
}, function(err, info){
  info.filename.should.eql('etc-20141224235999.tgz');
});
```

module.exports = () ->

