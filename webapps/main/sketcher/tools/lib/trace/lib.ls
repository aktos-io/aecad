export get-tid = (?.data?.aecad?.tid)

export is-trace = get-tid

export set-tid = (data={}, trace-id) ->
    unless data.aecad
        data.aecad = {}
    data.aecad.tid = trace-id
