#===================================================================
#--------------------------- Variables -----------------------------
#===================================================================
requirejsBuild = ./lib/client/vendor/requirejs/r.js
npmbin = node_modules/.bin

#===================================================================
#­--------------------------- TARGETS ------------------------------
#===================================================================
.PHONY : clean deps spec

#-------------------------------------------------------------------
# BUILD
#------------------------------------------------------------------- 
client: deps lib/client/src/cell.js lib/client/src/cell-pluginBuilder.js
	find ./lib/client/src -name '*.styl' -type f | xargs $(npmbin)/stylus --include lib/client/src/shared/styles --compress
	find ./lib/client/src -name '*.coffee' -type f | xargs $(npmbin)/coffee -c -b 
	node $(requirejsBuild) \
		-o \
		paths.requireLib=../vendor/requirejs/require \
		include=requireLib \
		name=cell!App \
		out=lib/client/src/bootstrap-tmp.js \
		baseUrl=lib/client/src includeRequire=true
	cat lib/client/src/bootstrap-tmp.js | $(npmbin)/uglifyjs -nc > lib/client/src/bootstrap.js
	mv lib/client/src/bootstrap-tmp.css lib/client/src/bootstrap.css
	rm lib/client/src/bootstrap-tmp.*

#-------------------------------------------------------------------
# TEST
#------------------------------------------------------------------- 
spec: deps
	for i in $$(ls spec/*.spec.coffee); do \
		echo "---- $$i ----"; \
		node_modules/.bin/jasmine-node --coffee "$$i"; \
	done
	#TODO: Figure out how to prevent node_redis from reconnecting,
	#      causing an error at the end LogPublisher, and borking
	#      jasmin-node from continuing on.
	# node_modules/.bin/jasmine-node --coffee spec/

#-------------------------------------------------------------------
# DEV 
#------------------------------------------------------------------- 
server: lib/server/HeadsupService.coffee deps
	$(npmbin)/coffee lib/server/HeadsupService.coffee

dev-stylus: deps
	find ./lib/client/src -name '*.styl' -type f | xargs $(npmbin)/stylus --include ./lib/client/src/shared/styles --watch --compress

dev-coffee: deps
	find ./lib/client/src -name '*.coffee' -type f | xargs $(npmbin)/coffee -c -b --watch

#-------------------------------------------------------------------
# Dependencies 
#------------------------------------------------------------------- 
deps:
	npm install

clean: 
	rm client/src/bootstrap.*
