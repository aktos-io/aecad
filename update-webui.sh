#!/bin/bash 
DIR=$(dirname "$(readlink -f "$0")")

$DIR/pull.sh
cd scada.js
[[ $1 = "--less" ]] || ./install-modules.sh
gulp --webapp main --production

