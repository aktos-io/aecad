#!/bin/bash 
DIR=$(dirname "$(readlink -f "$0")")

$DIR/pull.sh
[[ $1 = "--less" ]] || { ./scada.js/install-modules.sh; npm i; }
cd scada.js
gulp --webapp main --production
npm test
