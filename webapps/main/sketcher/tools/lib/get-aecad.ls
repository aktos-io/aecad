require! './get-class': {get-class}

export get-aecad = (item, parent) ->
    # Return aeCAD object
    type = item?.data?aecad?type
    if type
        return new (getClass type) do
            init:
                item: item
                parent: parent

export get-parent-aecad = (item-part) ->
    # Return parent aeCAD object's item
    # -----------------------------------
    item = switch item-part.getClassName?!
    | 'Segment', 'Curve' =>
        item-part.getPath!
    |_ =>
        item-part

    ae-item = null
    type = null
    tid = null
    for dig in [0 to 100]
        if (try get-class item?.data?.aecad?.type)
            # we have a valid ae-obj
            ae-item = item
            type = that
            tid = item?data?aecad?tid
        unless item.parent
            break
        if item.parent.getClassName! is \Layer
            break
        item = item.parent
    {item: ae-item, type, tid}
