require! './get-class': {get-class}

export get-aecad = (item, parent) ->
    # Return aeCAD object
    type = item.data?aecad?type
    if type
        return new (getClass type) do
            init:
                item: item
                parent: parent

export get-parent-aecad = (item-part) ->
    # Return parent aeCAD object by using the part (Segment, Curve, Pad, etc.)
    item = switch item-part.getClassName?!
    | 'Segment', 'Curve' =>
        item-part.getPath!
    | 'Path' =>
        item-part
    |_ => throw new Error "What is that?"

    ae-obj = null
    for dig in [0 to 100]
        try ae-obj = get-aecad item
        if item.parent.getClassName! is \Layer
            break
        item = item.parent
    {ae-obj, item}
