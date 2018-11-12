# convert multi-line, comma and/or space separated values
# into array
export text2arr = (text) ->
    text
        .replace /[\n,]/g, ' '
        .split " "
        .map (.trim!)
