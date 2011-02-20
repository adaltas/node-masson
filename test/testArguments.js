
var masson = require('masson'),
	assert = require('assert');

exports['test arguments in'] = function(){
	masson({
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
};

exports['test arguments out in object'] = function(){
	masson({
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
};
