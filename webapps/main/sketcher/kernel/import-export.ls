require! 'svgson'
require! 'pretty'
require! 'aea': {htmlDecode}

export do
    __export_svg__: ->
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

    export-svg: (opts={}, callback)->
        /*
            opts:
                mirror: bool
        */

        if typeof! opts is \Function
            callback = opts
            opts = {}

        _svg = @__export_svg__!

        # create svgson json ast
        p-svgson = svgson.parse _svg, do
            transformNode: (node) ->
                if node.attributes["data-paper-data"]
                    node.attributes["data-paper-data"] = JSON.parse htmlDecode that
                node

        svg <~ p-svgson.then
        #console.log "Svgson AST:", json

        # do postprocessing here
        if opts.mirror
            svg.attributes.transform = "scale(-1,1)"

        svg-str = pretty svgson.stringify svg, do
            transformAttr: (key, value, escape) ->
                switch key
                | 'data-paper-data' =>
                    "#{key}='#{escape JSON.stringify value}'"
                |_ =>
                    "#{key}='#{escape value}'"

        callback err=null, svg-str

    import-svg: (svg, callback) ->
        p-svgson = svgson.parse svg, do
            transformNode: (node) ->
                if node.attributes["data-paper-data"]
                    node.attributes["data-paper-data"] = JSON.parse htmlDecode that
                node
        back <~ p-svgson.then
        #console.log "Svgson AST Re-parsed:", back
        callback err=null, back

    export-json: ->
        old-zoom = @view.zoom
        @view.zoom = 1
        json = @project.exportJSON!
        @view.zoom = old-zoom # for above workaround
        return json
