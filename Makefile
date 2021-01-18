SHELL = /bin/bash

release:
	cd scada.js && make release APP=main

release-push:
	cd scada.js && make release-push

touch-app-version:
	cd scada.js && make update-app-version

development:
	./uidev.service

install-deps:
	@( cd scada.js; \
	[[ ! -d ./nodeenv ]] && make create-venv;\
	source ./venv; \
	make install-deps CONF=../dcs-modules.txt; \
	cd ..; \
	npm install; \
	echo ; \
	echo " *** All mandatory dependencies are installed. ***"; \
	echo ; \
	)

install-node-occ:
	( source scada.js/venv; \
	cd node_modules; \
	git clone --recursive https://github.com/ceremcem/node-occ; \
	cd node-occ; \
	./build.sh || true; \
	)

update:
	git pull
	git submodule update --recursive --init

