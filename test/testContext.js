
var masson = require('masson'),
	assert = require('assert');

exports['test context'] = function(){
	masson({
		'target 1': function(){
			this.out();
		},
		'target 2': function(){
			assert.equal('target 2',this.target);
			this.out();
			assert.equal('target 2',this.target);
		},
		'target 3': function(){
			var self = this;
			this.in(['target 1','target 2'],function(){
				assert.strictEqual(self,this);
				assert.equal('target 3',this.target);
				this.out();
				assert.equal('target 3',this.target);
			});
		}
	},'target 3');
};
