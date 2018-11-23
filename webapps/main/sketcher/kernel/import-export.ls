require! 'svgson'
require! 'pretty'
require! 'aea': {htmlDecode}
require! "json-stringify-pretty-compact": pretty-json
require! './svgson-to-dxf': {svgson-to-dxf}
require! '../lib/dxfToSvg': {dxfToSvg}
require! 'dcs/browser': {SignalBranch}
require! 'prelude-ls': {reverse, empty}

export do
    __export_svg: ->
        # Internal export-to-svg function
        # ----------------------------------
        # Start zooming workaround
        old-zoom = @view.zoom
        @view.zoom = 1
        # ...zooming workaround

        svg = @project.exportSVG do
            asString: true # Ensure data is immutable for below operations
            bounds: 'content'

        # end of zooming workaround
        @view.zoom = old-zoom
        return svg

    __export_json: ->
        old-zoom = @view.zoom
        @view.zoom = 1
        json = @project.exportJSON {as-string: no}
        @view.zoom = old-zoom # for above workaround
        return json

    # ------------------------------------------------------
    # Export
    # ------------------------------------------------------

    export-svg: (opts, callback) ->
        if typeof! opts is \Function
            callback = opts
            opts = {}

        opts.format = 'svg'
        @export opts, callback

    export: (opts={}, callback)->
        /*
            opts:
                mirror: bool
        */
        [callback, opts] = [opts, {}] if typeof! opts is \Function
        opts = {+pretty} <<< opts

        # create svgson json ast
        _svg = @__export_svg!
        err, svg <~ @svg-to-ast _svg

        # do postprocessing here
        # ------------------------------------------------------
        if opts.mirror
            svg.attributes.transform = "scale(-1,1)"

        svg.attributes.data = "aeCAD by Aktos Electronics, https://aktos.io/aecad"

        # Cleanup empty layers (layers that we never created)
        for i in reverse [til svg.children.length]
            child = svg.children[i]
            # first level is treated as "Layers"
            if empty (child?.children or [])
                console.warn "Deleting Layer?: ", child
                svg.children.splice i, 1
        console.log "Current svg: ", svg
        # ------------------------------------------------------

        err = null
        res = null
        switch opts.format
        | 'svg' =>
            res = pretty svgson.stringify svg, do
                transformAttr: (key, value, escape) ->
                    switch key
                    | 'data-paper-data' =>
                        "#{key}='#{escape JSON.stringify value}'"
                    |_ =>
                        "#{key}='#{escape value}'"
        | 'dxf' =>
            try
                res = svgson-to-dxf svg
            catch
                err = e
            PNotify.notice text: """
                TODO: There are unimplemented DXF types.
                See console.
                """
        | 'svgson' =>
            res = if opts.pretty
                pretty-json svg
            else
                JSON.stringify svg
        | 'json' =>
            res = pretty-json @__export_json!
        |_ =>
            err = "Extension is not recognized: #{opts.format}"

        callback err, res

    # ------------------------------------------------------
    # Import
    # ------------------------------------------------------

    svg-to-ast: (svg, callback) ->
        # Returns: svgson AST
        p-svgson = svgson.parse svg, do
            transformNode: (node) ->
                if node.attributes["data-paper-data"]
                    node.attributes["data-paper-data"] = JSON.parse htmlDecode that
                node
        json <~ p-svgson.then
        #console.log "Svgson AST Re-parsed:", json
        callback err=null, json


    import: (data, opts={}, callback) ->
        unless opts.format
            @vlog.error "Import needs format declaration."
            return

        b = new SignalBranch
        switch opts.format
        | 'json' =>
            @project.importJSON data
        | 'svg' =>
            #s = b.add!
            #err, json < ~ @svg-to-ast data
            # ... do the post processing here
            #s.go!
            PNotify.notice text: "TODO: Parse svg data correctly"
            @project.importSVG data
        | 'dxf' =>
            PNotify.notice text: "TODO: Splines can not be recognized"
            svg = dxfToSvg data
            @project.importSVG svg
        |_ =>
            err = "Extension is not recognized: #{opts.format}"

        err <~ b.joined

        # post-process the imported data
        # -------------------------------
        # * set selected = false
        # * assign layers to ractive variable
        # * cleanup temporary objects
        # -------------------------------
        for layer in @project.layers
            if layer.name
                @ractive.set "project.layers.#{Ractive.escapeKey layer.name}", layer
            else
                console.warn "No name layer: ", layer
            for layer.getChildren! when ..?
                ..selected = no
                if ..data?.tmp
                    ..remove!
        PNotify.success text: "#{name} imported."

        # inform the caller
        if typeof! callback is \Function
            callback err=null

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
