
REPORTER = dot

build:
	@./node_modules/.bin/coffee -b -o lib src/*.coffee

test: build
	@NODE_ENV=test ./node_modules/.bin/mocha \
		--compilers coffee:coffee-script \
		--reporter $(REPORTER)

coverage: build
	@istanbul cover _mocha -- -R spec --compilers coffee:coffee-script

.PHONY: test
