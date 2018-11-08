require! 'dcs/lib/keypath': {get-keypath, set-keypath}

export class ComponentBase
    # basic methods that every component should have
    set-data: (keypath, value) ->
        set-keypath @g.data.aecad, keypath, value

    get-data: (keypath) ->
        get-keypath @g.data.aecad, keypath
