
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon'),
	assertions = [];

var m = macon({
	'target 1': function(){
		this.depends('unregistered target',function(err){
			if(err){
				assertions.push(err.message);
			}
			this.next();
		});
	}
},'target 1');

m.on('error',function(context){
	assertions.push('error: '+context.target);
});

process.nextTick(function(){
	assert.deepEqual(
		['error: target 1','Invalid target: unregistered target'],
		assertions
	);
});