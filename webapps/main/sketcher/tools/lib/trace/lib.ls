require! 'dcs/lib/keypath': {get-keypath, set-keypath}

export get-tid = (?.data?.aecad?.tid)

export is-trace = get-tid

export set-tid = (data={}, trace-id) ->
    set-keypath data, 'data.aecad.tid', trace-id

export is-on-layer = (item, layer-name) ->
    aecad = get-keypath item, 'data.aecad'
    if aecad
        if that.layer in [layer-name, 'Edge']
            return true
        if that.type in <[ via drill ]>
            return true
    return false
