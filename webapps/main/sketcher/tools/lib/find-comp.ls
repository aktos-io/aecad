require! './get-aecad': {get-aecad}
require! '../../kernel': {PaperDraw}

export find-comp = (name) !->
    {project} = new PaperDraw
    for project.layers
        for ..getItems({-recursive})
            if ..data?aecad?name is name
                return get-aecad ..
    return null
