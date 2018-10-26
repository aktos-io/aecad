require! '../lib/dxfToSvg': {dxfToSvg}

export import_ = (ctx, file, next) ->
    pcb = @get \pcb

    if file.ext is \json
        pcb.project.importJSON file.raw
        for layer in pcb.project.layers
            if layer.name
                @set "project.layers.#{Ractive.escapeKey layer.name}", layer
            else
                console.log "No name layer: with #{layer.children.length} items: ", layer
            for layer.getChildren! when ..?
                ..selected = no
                if ..data?.tmp
                    ..remove!
        next!
        return

    <~ @fire \activateLayer, ctx, file.basename
    pcb.project.getActiveLayer!.clear!

    switch file.ext.to-lower-case!
    | 'svg' =>
        <~ pcb.project.importSVG file.raw
        process-objects = (o) ->
            if o.hasChildren!
                for o.children
                    process-objects ..
            else
                if project = o.data?project
                    # set the project properties
                    if project.layer
                        layers[project.layer].addChild o

        console.log "svg is imported: ", pcb.project
        #for layer in pcb.project.getItems!
        #    process-objects layer
        next!
    | 'dxf' =>
        # FIXME: Splines can not be recognized
        svg = dxfToSvg file.raw
        pcb.project.importSVG svg
        next!
    | 'json' =>
        debugger
        pcb.project.importJSON file.raw
        next!

importDXF2 = (ctx, file, next) ~>
    <~ @fire \activateLayer, ctx, \import
    import-layer = @get \project.layers.import
        ..clear!
        ..activate!
    # FIXME: Implement conversion spline to arc
    parsed = dxf.parseString file.raw
    svg = dxf.toSVG(parsed)
    create-download "import-dxf2.svg", svg
    #paper.project.clear!
    pcb.project.importSVG svg
    next!
