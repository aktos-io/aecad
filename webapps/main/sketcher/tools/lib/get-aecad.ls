require! './get-class': {get-class}

export getAecad = (item) ->
    # Return aeCAD object
    type = item.data?aecad?type
    return new (getClass type) do
        name: name
        init: item
