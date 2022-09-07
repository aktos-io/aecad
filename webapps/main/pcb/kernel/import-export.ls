require! 'svgson'
require! 'pretty'
require! 'aea': {htmlDecode}
require! "json-stringify-pretty-compact": pretty-json
require! './svgson-to-dxf': {svgson-to-dxf}
require! '../lib/dxfToSvg': {dxfToSvg}
require! 'dcs/browser': {SignalBranch}
require! 'prelude-ls': {reverse, empty}
require! './svgson-to-svg': {svgson-to-svg}

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

        unless svg.attributes.viewBox
            return callback err=null, res='''
                <?xml version="1.0" encoding="UTF-8" standalone="no"?>
                <svg
                   viewBox="0 0 210 297"
                   height="297mm"
                   width="210mm">
                </svg>
                '''

        # do postprocessing here
        # ------------------------------------------------------
        deps = require('app-version.json')
        project-info =
            name: "aeCAD by Aktos Electronics"
            website: "https://aktos.io/aecad"
            dependencies:
                aecad: deps.commit

        svg.attributes.data = project-info

        scale = opts.scale or 1

        if opts.mirror or scale isnt 1
            container = null
            if svg.children.length is 1 and svg.children.0.name is \g
                container = svg.children.0
            else
                container =
                    name: \g
                    type: \element
                    children: svg.children
                    attributes: {}
                svg.children = [container]

            [minx, miny, width, height] = svg.attributes.viewBox.split ',' .map (Number)

            s = scale
            container.attributes.transform = if opts.mirror
                "translate(#{s * (width + minx) + minx}, #{-miny * (s-1)}) scale(#{-s},#{s})"
            else
                "translate(#{-minx * (s-1)}, #{-miny * (s-1)}) scale(#{s},#{s})"
                

            if scale isnt 1
                svg.attributes
                    ..viewBox = "#{minx},#{miny},#{width * scale},#{height * scale}"
                    ..width = "#{width * scale}"
                    ..height = "#{height * scale}"


        #console.log "Current svg ast: ", svg
        # ------------------------------------------------------

        err = null
        res = null
        switch opts.format
        | 'svg' =>
            res = pretty svgson-to-svg svg
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
            paperjs-json = @__export_json!
                ..unshift ["aeCAD", project-info]
            res = pretty-json paperjs-json
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

                # for root node
                if node.attributes["data"]
                    node.attributes["data"] = JSON.parse htmlDecode that
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
            @importLayout data
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
        | 'svgson' =>
            # TODO: directly convert svgson to Paper.js JSON format
            # instead of first converting into SVG
            s = b.add!
            try
                throw "Importing from SVGSON doesn't work at the moment because this process uses SVG as the middle format"
                svg = svgson-to-svg JSON.parse data
                @project.importSVG svg
                s.go!
            catch
                s.go err=e.message
        |_ =>
            s = b.add!
            s.go err="Extension is not recognized: #{opts.format}"

        err, signals <~ b.joined
        if err
            @vlog.error err
            return

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
 
        PNotify.success text: "#{name} imported."

        # inform the caller
        if typeof! callback is \Function
            callback err=null

    importLayout: (json, name) -> 
        # json: is a stringified JSON
        name = name or @active-layout
        @selection.clear!
        try 
            if typeof! json is \String 
                JSON.parse json # verify that this is a JSON string 
            @project.importJSON json
        catch 
            debugger 
        for i from 0 to 10
            needs-rerun = false
            for layer in @project.layers
                unless layer
                    # workaround for possible Paper.js bug
                    # which can not handle more than a few
                    # hundred layers
                    console.warn "...we have an null layer!"
                    needs-rerun = true
                    continue

                if layer.name
                    @ractive.set "project.layers.#{Ractive.escapeKey layer.name}", layer
                else
                    PNotify.notice text: "Problematic layer is highlighted."
                    layer.selected = yes 

                for layer.getItems!
                    ..selected = no
                    if ..data?.tmp
                        ..remove!
            break unless needs-rerun
            console.warn "Workaround for load-project works."
        if i > 0
            PNotify.notice text: "importLayout rerun count: #{i+1}"

        unless name of @layouts 
            @layouts[name] = null
        @active-layout = name 

    switchLayout: (layout-name, opts={}) -> 
        # save current layout in ractive.data.layouts
        # load the target layout to the canvas
        return -1 unless layout-name?
        
        # save current layout 
        if @active-layout?
            unless opts.dont-save-current
                @layouts{}[@active-layout].layout = @project.exportJSON!
                if opts.script-name 
                    @layouts{}[@active-layout].script-name = that
        
        # load target layout if exists
        @clear-canvas!
        if @layouts[layout-name]?layout
            @project.clear!
            @project.importJSON that
        @register-layers!
        unless layout-name of @layouts 
            @layouts[layout-name] = null 
        @active-layout = layout-name 

    removeLayout: (name) -> 
        layouts = Object.keys @layouts 
        i = layouts.index-of name
        new-i = (((i + 1) % layouts.length) + layouts.length) % layouts.length
        @switch-layout layouts[new-i] 
        delete @layouts[name]
        @ractive.set 'layouts', Object.keys @layouts

importDXF2 = (ctx, file, next) ~>
    <~ @fire \activateLayer, ctx, \import
    import-layer = @get \project.layers.import
        ..clear!
        ..activate!
    # FIXME: Implement conversion spline to arc
    parsed = dxf.parseString file.raw
    svg = dxf.toSVG(parsed)
    create-download "import-dxf2.svg", svg
    pcb.project.importSVG svg
    next!
