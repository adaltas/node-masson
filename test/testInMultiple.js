
var masson = require('masson'),
	assert = require('assert');

exports['test multiple in in a same function'] = function(){
	var assertions = [];
	var m = masson({
		'target 1': function(){
			this.out();
		},
		'target 2': function(){
			this.out();
		},
		'target 3': function(){
			this.in('target 1',function(){
				this.out();
			});
			this.in('target 2',function(){
				this.out();
			});
		}
	},'target 3');
	m.on('before',function(context){
		assertions.push('before '+context.target);
	})
	m.on('after',function(context){
		assertions.push('after '+context.target);
	})
	
	process.nextTick(function(){
		assert.deepEqual(
			// Note how 'after target 3' is called twice
			['before target 3','before target 1','after target 1','after target 3','before target 2','after target 2','after target 3'],
			assertions
		);
	});
};
