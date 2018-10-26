require! 'prelude-ls': {flatten}
require! './tools/lib/selection': {Selection}

class History
    (opts) ->
        @project = opts.project
        @ractive = opts.ractive
        @selection = opts.selection
        @commits = []
        @limit = 20

    push: ->
        @commits.push @project.exportJSON!
        console.log "added to history"
        if @commits.length > @limit
            console.log "removing old history"
            @commits.shift!

    commit: ->
        @push!

    back: ->
        console.log "Going back in the history."
        commit = @commits.pop!
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
        @history = new History {@project, @selection, @ractive}

    get-all: ->
        # returns all items
        flatten [..getItems! for @project.layers]

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
        @add-layer name  # add the layer if it doesn't exist
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        layer.addChild item

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    cursor: (name) ->
        @canvas.style.cursor = name
