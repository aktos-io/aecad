require! 'paper'
window.paper = paper # required for PaperScope to work correctly
require! 'aea': {create-download}
require! './lib/dxfToSvg': {dxfToSvg}
require! './lib/svgToKicadPcb': {svgToKicadPcb}
require! 'svgson'
require! 'dxf-writer'
require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}
require! 'dxf'
require! 'livescript': lsc
require! 'prelude-ls': {abs}
require('jquery-mousewheel')($);

json-to-dxf = (obj, drawer) ->
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


Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        canvas = @find '#draw'
        canvas.width = 600
        canvas.height = 400

        pcb = paper.setup canvas
        pcb.activate!

        gui = new pcb.Layer!
        script-layer = new pcb.Layer!
        external = new pcb.Layer!

        changeZoom = (oldZoom, delta) ->
              factor = 1.05
              if delta < 0
                return oldZoom / factor
              if delta > 0
                return oldZoom * factor
              oldZoom

        changeZoomPointer = (oldZoom, delta, c, p) ->
          newZoom = changeZoom oldZoom, delta
          beta = oldZoom / newZoom
          pc = p.subtract c
          a = p.subtract(pc.multiply(beta)).subtract c
          [newZoom, a]

        $ canvas .mousewheel (event) ->
            mousePosition = new pcb.Point event.offsetX, event.offsetY
            viewPosition = pcb.view.viewToProject(mousePosition)
            [newZoom, offset] = changeZoomPointer pcb.view.zoom, event.deltaY, pcb.view.center, viewPosition
            pcb.view.zoom = newZoom
            pcb.view.center = pcb.view.center.add offset
            event.preventDefault()

        path = null
        freehand = new pcb.Tool!
            ..onMouseDrag = (event) ~>
                path.add(event.point);

            ..onMouseDown = (event) ~>
                gui.activate!
                path := new pcb.Path();
                path.strokeColor = 'black';
                path.add(event.point);

        trace =
            line: null
            snap-x: false
            snap-y: false
            seg-count: null

        trace-tool = new pcb.Tool!
            ..onMouseDrag = (event) ~>
                offset = event.downPoint .subtract event.point
                pcb.view.center = pcb.view.center .add offset
                trace.panning = yes

            ..onMouseUp = (event) ~>
                gui.activate!
                unless trace.panning
                    unless trace.line
                        trace.line = new pcb.Path(event.point, event.point)
                        trace.line.strokeColor = 'red'
                        trace.line.strokeWidth = 3
                    else
                        trace.line.add(event.point)
                trace.panning = no

            ..onMouseMove = (event) ~>
                if trace.line
                    lp = trace.line.segments[* - 1].point
                    l-pinned-p = trace.line.segments[* - 2].point
                    y-diff = l-pinned-p.y - event.point.y
                    x-diff = l-pinned-p.x - event.point.x
                    tolerance = 5

                    snap-y = false
                    snap-x = false
                    if event.modifiers.shift
                        angle = lp.subtract l-pinned-p .angle
                        console.log "angle is: ", angle
                        if angle is 90 or angle is -90
                            snap-y = true
                        else if angle is 0 or angle is 180
                            snap-x = true

                    if abs(y-diff) < tolerance or snap-x
                        # x direction
                        lp.x = event.point.x
                        lp.y = l-pinned-p.y
                    else if abs(x-diff) < tolerance or snap-y
                        # y direction
                        lp.y = event.point.y
                        lp.x = l-pinned-p.x
                    else if abs(x-diff - y-diff) < tolerance
                        # 45 degrees
                        lp.set event.point
                        trace.line.strokeColor = 'green'
                    else
                        lp.set event.point
                        trace.line.strokeColor = 'red'

                    # collision detection
                    search-hit = (src, target) ->
                        hits = []
                        if target.hasChildren!
                            for target.children
                                if search-hit src, ..
                                    hits ++= that
                        else
                            if src .is-close target.bounds.center, 10
                                # http://paperjs.org/reference/shape/
                                if target.constructor?.name in <[ Shape Path ]>
                                    if target.constructor.name is \Path and not target.closed
                                        null
                                    else
                                        #console.warn "Hit! ", target
                                        hits.push target
                                else
                                    console.log "Skipping hit: ", target
                        hits

                    for layer in pcb.project.getItems!
                        for obj in layer.children
                            for hit in event.point `search-hit` obj
                                if (dist = hit.bounds.center .subtract event.point .length) > 100
                                    console.log "skipping, too far ", dist
                                    continue
                                console.log "Snapping to ", hit
                                lp .set hit.bounds.center

            ..onKeyDown = (event) ~>
                if event.key is \escape
                    trace.line?.removeSegment (trace.line.segments.length - 1)
                    trace.line = null

        @observe \drawingLs, (_new) ~>
            compiled = no
            @set \output, ''
            try
                js = lsc.compile _new, {+bare, -header}
                compiled = yes
            catch err
                @set \output, err.to-string!

            if compiled
                try
                    #pcb.project.clear!
                    script-layer
                        ..activate!
                        ..clear!
                    pcb.execute js
                catch
                    @set \output, "#{e}\n\n#{js}"

        @on do
            changeTool: (ctx, tool, proceed) ~>
                console.log "Changing tool to: #{tool}"
                switch tool
                | \Tr => trace-tool.activate!
                | \Fh => freehand.activate!
                proceed!

            importSVG: (ctx, file, next) ~>
                #paper.project.clear!
                external
                    ..activate!
                    ..clear!
                <~ pcb.project.importSVG file.raw
                next!

            importDXF: (ctx, file, next) ~>
                # FIXME: Splines can not be recognized
                svg = dxfToSvg file.raw
                #paper.project.clear!
                external
                    ..activate!
                    ..clear!
                pcb.project.importSVG svg
                next!

            importDXF2: (ctx, file, next) ~>
                # FIXME: Implement conversion spline to arc
                parsed = dxf.parseString file.raw
                svg = dxf.toSVG(parsed)
                #paper.project.clear!
                external
                    ..activate!
                    ..clear!
                pcb.project.importSVG svg
                next!

            exportSVG: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                create-download "myexport.svg", svg

            exportDXF: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                res <~ svgson svg, {}
                drawing = new dxf-writer!
                json-to-dxf res, drawing
                dxf-out = drawing.toDxfString!
                create-download "export.dxf", dxf-out

            clear: (ctx) ~>
                gui.clear!
                #paper.project.clear!

            exportKicad: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
                try
                    kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
                catch
                    return ctx.component.error e.message
                create-download "myexport.kicad_pcb", kicad

    data: ->
        drawingLs: '''
            pad = (point=new Point(10, 10), size=new Size(20,20)) ->
                p = new Rectangle point, size
                pad = new Path.Rectangle p
                pad.fillColor = 'black'
                pad

            mm2px = ( / 25.4 * 96)

            P = (x, y) -> new Point (x |> mm2px), (y |> mm2px)
            S = (a, b) -> new Size (a |> mm2px), (b |> mm2px)

            do ->
                p1 = pad P(4mm, 2mm), S(2mm, 4mm)
                pad P(p1.bounds.left, p1.bounds.bottom + (5 |> mm2px))
            '''

        kicadLayers:
            \F.Cu
            \B.Cu
            \B.Adhes
            \F.Adhes
            \B.Paste
            \F.Paste
            \B.SilkS
            \F.SilkS
            \B.Mask
            \F.Mask
            \Dwgs.User
            \Cmts.User
            \Eco1.User
            \Eco2.User
            \Edge.Cuts
