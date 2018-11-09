require! './get-class': {get-class}

export getAecad = (item, parent) ->
    # Return aeCAD object
    type = item.data?aecad?type
    if type
        return new (getClass type) do
            init:
                item: item
                parent: parent
