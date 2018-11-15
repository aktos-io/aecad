# convert multi-line, comma and/or space separated values
# into array
export text2arr = (text) ->
    text
        .replace /[\n,\s]+/g, ' '
        .split ' '
        .filter (-> !!it)   # Remove falsy values
        .map (.trim!)
