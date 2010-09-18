
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon');
	
var m = macon({
	'target aaa': function(){
		this.out('target aaa');
	},
	'target aa': function(){
		this.in('target aaa',function(err,argsTarget0){
			assert.deepEqual([null,['target aaa']],Array.prototype.slice.call(arguments));
			this.out('target aa');
		});
	},
	'target aba': function(){
		this.out('target aba');
	},
	'target abca': function(){
		this.out('target abca');
	},
	'target abc': function(){
		this.in('target abca',function(err,argsTarget0){
			assert.deepEqual([null,['target abca']],Array.prototype.slice.call(arguments));
			this.out('target abc');
		});
	},
	'target ab': function(){
		this.in(['target aba','target abc'],function(err,argsTarget0){
			assert.deepEqual([null,['target aba'],['target abc']],Array.prototype.slice.call(arguments));
			this.out('target ab arg 1','target ab arg 2');
		});
	},
	'target a': function(err,arg1,arg2){
		this.in(['target aa','target ab'],function(err,argsTarget1,argsTarget2){
			assert.deepEqual([null,['target aa'],['target ab arg 1','target ab arg 2']],Array.prototype.slice.call(arguments));
			this.out();
		});
	}
},'target a');
