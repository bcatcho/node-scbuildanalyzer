test:
	mocha --watch --colors --growl --compilers coffee:coffee-script --reporter spec

.PHONY: test
