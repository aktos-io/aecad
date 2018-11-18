/*
export function getClass data
    name = data?aecad?type or data
    if name.match /^[a-zA-Z0-9_]+$/
        eval name
    else
        throw new Error "Arbitrary code execution is not allowed."
*/

ae-classes = {}

export get-class = (data) ->
    name = data?aecad?type or data
    if name? and ae-classes[name]
        return that
    else
        throw new Error "Can not find type: #{name}"

export add-class = (cls) ->
    #console.log "Registering component type:", cls.name
    ae-classes[cls.name] = cls

export list-classes = ->
    Object.keys ae-classes
