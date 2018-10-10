require! paper
require! 'aea': {create-download}
require! './dxfToSvg': {dxfToSvg}
require! 'svgson'
require! 'dxf-writer'
require! 'svg-path-parser': {parseSVG:parsePath, makeAbsolute}

Ractive.components['sketcher'] = Ractive.extend do
    template: RACTIVE_PREPARSE('index.pug')
    onrender: ->
        canvas = @find '#draw'
        paper.setup canvas
        path = new paper.Path();
        path.strokeColor = 'black';
        start = new paper.Point(100, 100);
        path.moveTo(start);
        path.lineTo(start.add([ 200, -50 ]));
        paper.view.draw();

        line-tool = new paper.Tool!
            ..onMouseDrag = (event) ~>
                path.add(event.point);

        @on do
            exportSVG: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                create-download "myexport.svg", svg

            importSVG: (ctx, file, next) ~>
                paper.project.clear!
                <~ paper.project.importSVG file.raw
                next!

            importDXF: (ctx, file, next) ~>
                svg = dxfToSvg file.raw
                paper.project.clear!
                paper.project.importSVG svg
                next!

            exportDXF: (ctx) ~>
                svg = paper.project.exportSVG {+asString}
                res <~ svgson svg, {}
                json-to-dxf = (obj, drawer) ->
                    switch obj.name
                    | \path =>
                        for attr, val of obj.attrs
                            switch attr
                            | \d =>
                                console.log "value is: ", val
                                walk = parsePath val |> makeAbsolute
                                for step in walk
                                    switch step.command
                                    | "moveto" =>
                                        # FIXME: do not draw line, just move there
                                        drawer.drawLine(step.x0, step.y0, step.x, step.y)
                                    | "lineto" =>
                                        drawer.drawLine(step.x0, step.y0, step.x, step.y)

                    if obj.childs?
                        for child in obj.childs
                            json-to-dxf child, drawer

                drawing = new dxf-writer!
                json-to-dxf res, drawing
                dxf-out = drawing.toDxfString!
                create-download "export.dxf", dxf-out
