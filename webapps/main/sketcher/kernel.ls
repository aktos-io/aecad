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
        if @commits.length > @limit
            @commits.shift!

    back: ->
        commit = @commits.pop!
        if commit
            for @project.layers
                ..clear!
            @selection.clear!
            @project.importJSON commit
            for layer in @project.layers
                if layer.name
                    @ractive.set "project.layers.#{layer.name}", layer
                else
                    console.log "No name layer: with #{layer.children.length} items: ", layer
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
            for k, v of that
                this[k] = v
        @ractive = that if opts.ractive
        @canvas = that if opts.canvas
        @tools = {}
        @selection = new Selection
        @history = new History {@project, @selection, @ractive}

    get-all: ->
        # returns all items
        flatten [..getItems! for @project.layers]


    add-layer: (name) ->
        @use-layer name

    use-layer: (name) ->
        if @ractive.get "project.layers.#{name}"
            that.activate!
        else
            layer = new @Layer!
                ..name = name
            @ractive.set "project.layers.#{name}", layer
        @ractive.set \activeLayer, name

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    cursor: (name) ->
        @canvas.style.cursor = name
