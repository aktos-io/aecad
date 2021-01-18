#!/usr/bin/lsc --prelude
args = process.argv.slice(4) # because --prelude is used.
echo = console.log
exit = process.exit
# ------------------------

require! fs
require! path

src = args.0
unless src 
    throw new Error "first param: source script"

x = require(src)
dir = path.parse(src).name
unless fs.existsSync(dir)
    echo "creating #dir directory..."
    fs.mkdirSync(dir)
else
    throw new Error "#dir exists"

for name, content of x
    fs.writeFileSync "./#{dir}/#{name}.ls", content
