require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}

export json-to-dxf = (obj, drawer) ->
    '''
    obj: JSON object, svgson v2 AST
    '''
    switch obj.name
    | \svg => # do nothing
    | \g => # there are no groups in DXF, right?
    | \defs => # currently we don't have anything to do with defs
    | \path =>
        for attr, val of obj.attributes
            switch attr
            | \d =>
                walk = parsePath val |> makeAbsolute
                for step in walk
                    if step.command is \moveto
                        continue
                    else if step.code in <[ l L h H v V Z ]> =>
                        drawer.drawLine(step.x0, -step.y0, step.x, -step.y)
                    else
                        console.warn "what is that: ", step.command
    | \circle =>
        console.warn "NOT IMPLEMENTED circle"
    |_ =>
        console.error "NOT IMPLEMENTED element type: ", obj
        throw "NOT IMPLEMENTED"

    if obj.children?
        for child in obj.children
            json-to-dxf child, drawer
