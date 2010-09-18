
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon');
	
var m = macon({
	'target 0': function(){
		assert.deepEqual(['my arg 0'],Array.prototype.slice.call(arguments));
		this.out();
	},
	'target 1': function(){
		assert.deepEqual(['my arg 1 & 2'],Array.prototype.slice.call(arguments));
		this.in('target 0',['my arg 0'],function(){
			this.out();
		});
		this.out();
	},
	'target 2': function(){
		assert.deepEqual(['my arg 1 & 2'],Array.prototype.slice.call(arguments));
		this.out();
	},
	'target 3': function(err,arg1,arg2){
		assert.deepEqual(['my first arg 3','my second arg 3'],Array.prototype.slice.call(arguments));
		this.in(['target 1','target 2'],['my arg 1 & 2'],function(){
			this.out();
		});
	}
},'target 3',['my first arg 3','my second arg 3']);
