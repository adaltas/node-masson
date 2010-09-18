
<pre>
                        _ __ ___   __ _  ___ ___  _ __  
                       | '_ ` _ \ / _` |/ __/ _ \| '_ \ 
                       | | | | | | (_| | (_| (_) | | | |
                       |_| |_| |_|\__,_|\___\___/|_| |_|
                                          ±
</pre>

Maçon is similar to tools like Make, Ant or Rake. It provides a simple workflow system where a target may be called along with others target it depends on.


Maçon by exemple
----------------

Choose your style..

	var macon = require('macon');
	
	macon({
	'build' : function(){
		this.in([ 'prepare', 'clean' ],function(){
			/* do something */ 
		});
	},{
	prepare' : function(){
		/* do some setup */
		this.out(); }
	},{
	'clean' : function(){
		/* do some cleaning */
		this.out(); }
	});

..could (soon) be rewritten as

	macon([{
		target: build'',
		prerequisites: [ 'prepare', 'clean' ],
		recipe: function(){
			this.out();
		}
	},{
		target: 'prepare',
		recipe: function(){
			/* do some setup */
			this.out();
		}
	},{
		target: 'clean',
		recipe: function(){
			setTimeout(function(){
				/* do some cleaning */
				this.out();
			},1000);
		}
	}]);


