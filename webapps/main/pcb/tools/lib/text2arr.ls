require! 'dcs/lib/test-utils': {make-tests}

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

make-tests "text2arr", do
    1: -> 
        expect text2arr "a b c d"
        .to-equal <[ a b c d ]> 
    2: -> 
        expect text2arr "a, b, c, d"
        .to-equal <[ a b c d ]> 
    3: -> 
        expect text2arr "a, , ,b, c, d,"
        .to-equal <[ a b c d ]> 
    4: -> 
        expect text2arr <[ a b c d ]>
        .to-equal <[ a b c d ]> 
    5: -> 
        arr = 
            "a b c d"
            "e f g h"

        expect text2arr arr  
        .to-equal <[ a b c d e f g h ]> 
    6: -> 
        expect text2arr ""
        .to-equal []
