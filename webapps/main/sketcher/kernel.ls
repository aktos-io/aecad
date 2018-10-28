require! 'prelude-ls': {flatten}
require! './tools/lib/selection': {Selection}
require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! 'actors': {BrowserStorage}

class History
    (opts) ->
        @project = opts.project
        @ractive = opts.ractive
        @selection = opts.selection
        @db = opts.db
        @commits = []
        @limit = 20

    push: ->
        console.warn "DEPRECATED! use .commit! instead."
        @commit!

    commit: ->
        @commits.push @project.exportJSON!
        console.log "added to history"
        if @commits.length > @limit
            console.log "removing old history"
            @commits.shift!

    back: (data) ->
        console.log "Going back in the history."
        commit = data or @commits.pop!
        if commit
            for @project.layers
                ..clear!
            @selection.clear!
            @project.importJSON commit
            for layer in @project.layers
                if layer.name
                    @ractive.set "project.layers.#{Ractive.escapeKey layer.name}", layer
                for layer.getChildren! when ..?
                    ..selected = no
                    if ..data?.tmp
                        ..remove!

    save: ->
        data = @project.exportJSON!
        @db.set \project, data
        console.log "Saved at ", Date!, "length: #{parseInt(data.length/1024)}KB"

    load: ->
        if @db.get \project
            @back that


export class PaperDraw
    @instance = null
    (opts={}) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this

        if opts.scope
            @_scope = opts.scope
            for k, v of that
                this[k] = v
        @ractive = that if opts.ractive
        @canvas = that if opts.canvas
        @tools = {}
        @selection = new Selection
            ..scope = this
            ..on \selected, (items) ~>
                selected = items.0
                return unless selected
                @ractive.set \selectedProps, selected
                @ractive.set \propKeys, do
                    fillColor: \color
                    strokeWidth: \number
                    strokeColor: \color

                @ractive.set \aecadData, (selected.data?aecad or {})
                console.log selected

            ..on \cleared, ~>
                @ractive.set \propKeys, {}
                @ractive.set \aecadData, {}

        @db = new BrowserStorage "sketcher"
        @history = new History {
            @project, @selection, @ractive
            @db
        }
        # try to load if a project exists
        @history.load!

        $ window .on \unload, ~>
            @history.save!


    get-all: ->
        # returns all items
        flatten [..getItems! for @project.layers]

    get-flatten: (opts={}) ->
        '''
        opts:
            containers: [bool] If true, "Group"s and "Layers" are also included
        '''
        items = []
        make-flatten = (item) ->
            r = []
            if item.hasChildren!
                for item.children
                    if ..hasChildren!
                        if opts.containers
                            r.push ..
                        r ++= make-flatten ..
                    else
                        r.push ..
            else
                r.push item
            return r

        for @project.layers
            items ++= make-flatten ..
        items

    clean-tmp: ->
        for @get-all! when ..data?tmp
            ..remove!

    add-layer: (name) ->
        @use-layer name

    use-layer: (name) ->
        if @ractive.get "project.layers.#{Ractive.escapeKey name}"
            that.activate!
        else
            layer = new @Layer!
                ..name = name
            @ractive.set "project.layers.#{Ractive.escapeKey name}", layer
        @ractive.set \activeLayer, name

    send-to-layer: (item, name) ->
        set-keypath item, 'data.aecad.layer', name
        @add-layer name  # add the layer if it doesn't exist
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        layer.addChild item

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    cursor: (name) ->
        @canvas.style.cursor = name

    export-svg: ->
        old-zoom = @view.zoom
        @view.zoom = 1
        svg = @project.exportSVG do
            asString: true
            bounds: 'content'
        @view.zoom = old-zoom # for above workaround
        return svg

    export-json: ->
        old-zoom = @view.zoom
        @view.zoom = 1
        json = @project.exportJSON!
        @view.zoom = old-zoom # for above workaround
        return json
