require! './get-class': {get-class, list-classes}

export get-aecad = (item-part, parent-ae) ->
    # rehydrate an aeCAD object by its child or root graphic item
    unless item-part
        return null

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

            unless tmp.parent
                # no parent item available
                break

            if tmp.parent.getClassName! is \Layer
                # reached top level
                break

            # we have parent item available, continue searching
            tmp = tmp.parent

        # Detect the parent item
        {ae-item: parent-item, type: parent-type} = if parent.ae-item => parent else self
        item-is-root = if self.type and not parent.type then yes else no

    ae-obj = null
    if parent-type
        # an item for aeCAD object is detected
        # We may need both `init` data and original data at the same time 
        # while rehydrating the object (because the object may depend on the original
        # data to override another class. It might use `data.value` before calling
        # the `super` function.)
        orig-data = {...parent-item.data.aecad}
        
        ae-obj = new (getClass parent-type) orig-data <<< do 
            init:
                item: parent-item
                parent: parent-ae

        # Let's double check that we detected the correct parent. 
        # If ae-obj (at this point) is the correct parent, then "self.ae-item.id"
        # must be its child.
        unless item-is-root
            # `self` was not the root ae-item, we should return related ae-obj
            child = ae-obj.get {item: self.ae-item.id} .0
            unless child
                throw new Error "We lost the child! (couldn't find item id: #{self.ae-item.id})"
            else
                ae-obj = child
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
        _type_name = item?.data?.aecad?.type
        if (try get-class _type_name)
            # we have a valid ae-obj
            ae-item = item
            type = that
            tid = item?data?aecad?tid
        else if _type_name
            throw new Error "No such component found: #{_type_name}"
        unless item.parent
            break
        if item.parent.getClassName! is \Layer
            break
        item = item.parent
    {item: ae-item, type, tid}
