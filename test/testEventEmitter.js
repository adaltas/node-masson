
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon'),
	assertions = [];
	
var m = macon({
	'target 1': function(){
		this.next();
	},
	'target 2': function(){
		this.depends('target 1',function(){
			this.next();
		});
	}
},'target 2');
m.on('before',function(context){
	assertions.push('before '+context.target);
})
m.on('after',function(context){
	assertions.push('after '+context.target);
})

process.nextTick(function(){
	assert.deepEqual(
		['before target 2','before target 1','after target 1','after target 2'],
		assertions
	);
});