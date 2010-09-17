
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon'),
	assertions = [];

var m = macon({
	'target 1': function(){
		this.depends(['unregistered target 1','unregistered target 2'],function(err){
			if(err){
				assertions.push(err.message);
			}
			this.next();
		});
	}
},'target 1');

m.on('error',function(){
	assertions.push('error: '+this.target);
});

process.nextTick(function(){
	assert.deepEqual(
		['error: target 1','Invalid target: unregistered target 1'],
		assertions
	);
});