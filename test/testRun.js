
var masson = require('masson'),
	assert = require('assert');

exports['test calling run method'] = function(){
	var assertions = [];
	masson({
		'target 1': function(){
			this.out();
		},
		'target 2': function(){
			this.in('target 1',function(){
				this.out();
			});
		}
	})
	.run('target 2')
	.on('before',function(context){
		assertions.push('before '+context.target);
	})
	.on('after',function(context){
		assertions.push('after '+context.target);
	});
	
	process.nextTick(function(){
		assert.deepEqual(
			['before target 2','before target 1','after target 1','after target 2'],
			assertions
		);
	});
};
