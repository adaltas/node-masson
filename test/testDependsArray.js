
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon'),
	assertions = [];
	
var m = macon({
	'target 1': function(){
		this.next();
	},
	'target 2': function(){
		this.next();
	},
	'target 3': function(){
		this.depends(['target 1','target 2'],function(){
			this.next();
		});
	}
},'target 3');
m.on('before',function(){
	assertions.push('before '+this.target);
})
m.on('after',function(){
	assertions.push('after '+this.target);
})

process.nextTick(function(){
	assert.deepEqual(
		['before target 3','before target 1','after target 1','before target 2','after target 2','after target 3'],
		assertions
	);
});