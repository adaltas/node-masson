
var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon');
	
var m = macon({
	'target 1': function(){
		this.next();
	},
	'target 2': function(){
		assert.equal('target 2',this.target);
		this.next();
		assert.equal('target 2',this.target);
	},
	'target 3': function(){
		this.depends(['target 1','target 2'],function(){
			assert.equal('target 3',this.target);
			this.next();
			assert.equal('target 3',this.target);
		});
	}
},'target 3');
