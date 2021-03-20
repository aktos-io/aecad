# convert multi-line, comma and/or space separated values
# into array
export text2arr = (text) ->
    text = text or ''
    if typeof! text is \Array 
        text = text.join ','
    if typeof! text is \String 
        text
            .replace /[\n,\s]+/g, ' '
            .split ' '
            .filter (-> !!it)   # Remove falsy values
            .map (.trim!)
    else 
        throw new Error "Unsupported operand type: #{typeof! text}"
