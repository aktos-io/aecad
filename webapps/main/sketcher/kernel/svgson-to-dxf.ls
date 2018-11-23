require! 'dxf-writer'
require! 'dxf'
require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}

svg-to-dxf = (obj, drawer) ->
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
                        console.error "what is that: ", step.command
            |_ => console.error "What is that attribute?"
    | \circle =>
        console.error "Unimplemented element: circle:", obj
    |_ =>
        console.error "NOT IMPLEMENTED element type: ", obj

    # Recursively walk through nodes
    for child in obj.children or []
        svg-to-dxf child, drawer

export svgson-to-dxf = (svg, drawer) ->
    '''
    obj: Svgson v3 AST
    '''
    drawing = new dxf-writer!
    svg-to-dxf svg, drawing
    return drawing.toDxfString!
