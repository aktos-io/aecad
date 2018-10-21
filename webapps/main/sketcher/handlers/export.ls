require! 'svgson-next': svgson
require! 'aea': {create-download, htmlDecode}
require! 'pretty'

export export_ = (ctx) ->
    # VERY IMPORTANT: Might be needed by a bug.
    # changing view.zoom adds <g scale(...) />, so everything
    # is printed scaled
    action, data <~ @get \vlog .yesno do
        title: 'Filename'
        icon: ''
        closable: yes
        template: RACTIVE_PREPARSE('../gui/export-dialog.pug')
        buttons:
            save:
                text: 'Save'
                color: \green
            cancel:
                text: \Cancel
                color: \gray
                icon: \remove

    if action in [\hidden, \cancel]
        console.log "Cancelled."
        return

    filename = data.filename
    ext = (.split('.').pop!?.to-lower-case!)

    # create svg
    pcb = @get \pcb
    old-zoom = pcb.view.zoom
    pcb.view.zoom = 1

    _svg = pcb.project.exportSVG do
        asString: true
        bounds: 'content'

    _json = pcb.project.exportJSON!
    debugger 
    pcb.view.zoom = old-zoom # for above workaround

    # create svgson json ast
    transformNode = (node) ->
        if node.attributes["data-paper-data"]
            node.attributes["data-paper-data"] = htmlDecode that
        node
    json <~ svgson.parse _svg, {transformNode} .then

    switch filename |> ext
    | 'svg' =>
        svg = svgson.stringify json |> pretty
        create-download filename, svg
    | 'dxf' =>
        drawing = new dxf-writer!
        json-to-dxf json, drawing
        dxf-out = drawing.toDxfString!
        create-download filename, dxf-out


# TODO:

exportJSON = (ctx) ->
    json = pcb.project.exportJSON!
    @set \pjson, json  # for debugging purposes
    create-download "myexport.json", json

exportKicad = (ctx) ~>
    svg = pcb.project.exportSVG {+asString}
    #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
    try
        kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
    catch
        return ctx.component.error e.message
    create-download "myexport.kicad_pcb", kicad
