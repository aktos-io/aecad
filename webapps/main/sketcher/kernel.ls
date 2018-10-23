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

    get-all: ->
        # returns all items

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
