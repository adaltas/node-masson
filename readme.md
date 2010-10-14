
<pre>
            _ __ ___   __ _ ___ ___  ___  _ __  
           | '_ ` _ \ / _` / __/ __|/ _ \| '_ \ 
           | | | | | | (_| \__ \__ \ (_) | | | |
           |_| |_| |_|\__,_|___/___/\___/|_| |_|
</pre>

Masson is similar to tools like Make, Ant or Rake. It provides a simple workflow system where a target may be called along with others target it depends on.

Masson provide the following functionnalities:

*   fully asynch, call the out method when you done with a rule
*   evented by extending the Node EventEmitter
*   flexible by providing alternative configuration to feet your style
*   tested (using Expresso)
*   arguments transmission between targets

Masson by example
----------------

Choose your style..

	#!/usr/bin/env node
	var masson = require('masson');
	
	masson()
	.task( 'build', [ 'prepare', 'clean' ], function(){
		this.out();
	})
	.task( 'prepare', function(){
		this.out();
	})
	.task( 'clean', function(){
		var self = this;
		setTimeout(function(){
			/* do some cleaning */
			self.out();
		},1000);
	})
	.run('build');

..could be rewritten (and mixed) as

	#!/usr/bin/env node
	var masson = require('masson');
	
	masson([{
		target: 'build',
		depends: [ 'prepare', 'clean' ],
		callback: function(){
			this.out();
		}
	},{
		target: 'prepare',
		callback: function(){
			/* do some setup */
			this.out();
		}
	},{
		target: 'clean',
		callback: function(){
			var self = this;
			setTimeout(function(){
				/* do some cleaning */
				self.out();
			},1000);
		}
	}],'build');

..could be rewritten (and mixed) as

	#!/usr/bin/env node
	var masson = require('masson');
	
	masson({
	build : function(){
		this.in([ 'prepare', 'clean' ],function(){
			/* do something */ 
		});
	},
	prepare : function(){
		/* do some setup */
		this.out();
	},
	clean : function(){
		/* do some cleaning */
		this.out(); }
	}).run('build');

Using Masson
------------

When you require Masson as `var masson = require('masson');`, you receive a function. Simply call it with the following arguments:

*   array or object configuration (see the two styles above)
*   optional target to execute (save the pain of calling `my_masson.run('my target')`
*   optional argument to pass to the executed target

Listening to events
-------------------

Masson extends Node EventEmitter class and emits 3 events: "before", "after" and "error". Not rocket science but if you want to look at its behavior, almost all the tests use it.

Passing arguments
-----------------

Arguments may be transfered from parent to dependencies and from dependencies to parent callbacks.

The `in` method may receive an array of paramenters as a second argument, after the target(s). The same array will be available to all targets. The `out` method may also receive an array of parameter as its first argument and the parent will get as first parameter and error and for the following one as many parameter as there were child targets to call. I'm aware for not being clear but you can take a look at the test in `test/testArguments.js`.

Running the tests
-----------------

Tests are executed with expresso. To install it, simple use `npm install expresso`.

To run the tests
	expresso -I lib test/*

To develop with the tests watching at your changes
	expresso -w -I lib test/*

To instrument the tests
	expresso -I lib --cov test/*

Related projects
----------------

*   Matthew Eernisse "Node Jake": <http://github.com/mde/node-jake>
*   James Coglan's "Jake": <http://github.com/jcoglan/jake>
*   280 North's Jake: <http://github.com/280north/jake>

