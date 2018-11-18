# convert multi-line, comma and/or space separated values
# into array
export text2arr = (text) ->
    (text or '')
        .replace /[\n,\s]+/g, ' '
        .split ' '
        .filter (-> !!it)   # Remove falsy values
        .map (.trim!)
