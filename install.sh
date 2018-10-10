#!/bin/bash
set -eu -o pipefail
safe_source () { [[ ! -z ${1:-} ]] && source $1; _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; _sdir=$(dirname "$(readlink -f "$0")"); }; safe_source
# end of bash boilerplate

cd $_sdir
./scada.js/install-modules.sh
npm install
cd node_modules
git clone --recursive https://github.com/ceremcem/node-occ
cd node-occ
npm install
