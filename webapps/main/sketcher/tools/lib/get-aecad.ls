require! './get-class': {get-class, list-classes}

export get-aecad = (item-part, parent-ae) ->
    # rehydrate an aeCAD object by its child or root graphic item

    if parent-ae
        item-is-root = yes
        parent-item = item-part
        parent-type = parent-item.data?aecad?type
    else
        # find the parent item (if possible)
        item = switch item-part.getClassName?!
        | 'Segment', 'Curve' =>
            item-part.getPath!
        |_ =>
            item-part

        self =
            item: item      # immediate item that belongs to the item-part
            ae-item: null   # immediate the ae-item that belongs to the @item
            type: null      # ae-obj type of @ae-item

        parent =
            ae-item: null
            type: null

        tmp = item
        for dig in [0 to 1000]
            type = tmp?.data?.aecad?.type
            if type in list-classes!
                # we have a valid ae-obj
                unless self.ae-item
                    self.ae-item = tmp
                    self.type = type
                else
                    parent.ae-item = tmp
                    parent.type = type

            if tmp.parent.getClassName! is \Layer
                # reached top level
                break

            unless tmp.parent
                # no parent item available
                break
            else
                # we have parent item available, continue searching
                tmp = tmp.parent

        # Detect the parent item
        {ae-item: parent-item, type: parent-type} = if parent.ae-item => parent else self
        item-is-root = if self.type and not parent.type then yes else no

    ae-obj = null
    if parent-type
        # an item for aeCAD object is detected
        ae-obj = new (getClass parent-type) do
            init:
                item: parent-item
                parent: parent-ae

        unless item-is-root
            # `self` was not the root ae-item, we should return related ae-obj
            for ae-obj.pads when ..g.id is self.ae-item.id
                ae-obj = ..
                console.log "Returning ae-obj: ", ae-obj
                break

    return ae-obj


/*
export get-aecad = (item, parent) ->
    # Return aeCAD object
    type = item?.data?aecad?type
    if type
        return new (getClass type) do
            init:
                item: item
                parent: parent
*/

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
