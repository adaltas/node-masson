
var masson = require('masson'),
	assert = require('assert');

exports['test calling task method'] = function(){
	var assertions = [];
	masson()
	.task('target 1',function(){
		this.out();
	})
	.task('target 2','target 1',function(){
		this.out();
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
			['before target 1','after target 1','before target 2','after target 2'],
			assertions
		);
	});
};
