require! 'svgson-next': svgson
require! 'aea': {create-download, htmlDecode}
require! 'dcs/browser': {SignalBranch}
require! 'pretty'
ext = (.split('.').pop!?.to-lower-case!)

export export_ = (ctx, _filename) ->
    b = new SignalBranch
    filename = null
    if _filename
        filename = _filename
    else
        s = b.add!
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
            b.cancel!
            return
        filename := data.filename
        s.go!
    <~ b.joined
    # create svg
    pcb = @get \pcb
    old-zoom = pcb.view.zoom
    pcb.view.zoom = 1

    _svg = pcb.project.exportSVG do
        asString: true
        bounds: 'content'
    _json = pcb.project.exportJSON!
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
    | 'json' =>
        # Paper.js native json format
        j2 = []
        for JSON.parse _json
            if ..0 is \Layer and ..1.children?
                j2.push ..
            else
                console.warn "what is that: ", ..
        console.log j2
        create-download filename, JSON.stringify(j2, null, 2)


# TODO:
exportKicad = (ctx) ~>
    svg = pcb.project.exportSVG {+asString}
    #svgString, title, layer, translationX, translationY, kicadPcbToBeAppended, yAxisInverted)
    try
        kicad = svgToKicadPcb svg, 'hello', \Edge.Cuts, 0, 0, null, false
    catch
        return ctx.component.error e.message
    create-download "myexport.kicad_pcb", kicad
