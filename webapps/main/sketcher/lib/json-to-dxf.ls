require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}

export json-to-dxf = (obj, drawer) ->
    switch obj.name
    | \svg => # do nothing
    | \g => # there are no groups in DXF, right?
    | \defs => # currently we don't have anything to do with defs
    | \path =>
        for attr, val of obj.attrs
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
        debugger
    |_ => debugger
    if obj.childs?
        for child in obj.childs
            json-to-dxf child, drawer
