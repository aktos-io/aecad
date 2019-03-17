#!/bin/bash 
DIR=$(dirname "$(readlink -f "$0")")

$DIR/pull.sh
[[ $1 = "--less" ]] || { ./scada.js/install-modules.sh; npm i; }
cd scada.js
./production-build.sh main
npm test
