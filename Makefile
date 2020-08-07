SHELL = /bin/bash

production:
	cd scada.js && make production APP=main

install-deps:
	@( cd scada.js; \
	make create-venv 2> /dev/null; \
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

