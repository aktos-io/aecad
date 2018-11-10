require! 'prelude-ls': {flatten}
require! './line': {Line}

export canvas-control =
    get-top-item: (item) ->
        if @ractive.get \selectGroup
            # select the top level group
            for dig in  [0 to 100]
                if item.parent.getClassName! is \Layer
                    break
                item = item.parent
            console.log "Dig level: ", dig
            item
        else
            item

    get-bounds: ->
        # returns overall bounds
        items = flatten [..getItems! for @project.layers]
        bounds = items.reduce ((bbox, item) ->
            unless bbox => item.bounds else bbox.unite item.bounds
            ), null
        #console.log "found items: ", items.length, "bounds: #{bounds?.width}, #{bounds?.height}"
        return bounds

    cursor: (name) ->
        prev = @canvas.style.cursor
        @canvas.style.cursor = name
        prev

    clean-tmp: ->
        for @get-all! when ..data?tmp
            ..remove!

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

    add-layer: (name) ->
        @use-layer name

    use-layer: (name) ->
        layer = null
        if @ractive.get "project.layers.#{Ractive.escapeKey name}"
            layer = that
                ..activate!
        else
            layer = new @Layer!
                ..name = name
            @ractive.set "project.layers.#{Ractive.escapeKey name}", layer
        @ractive.set \activeLayer, name
        layer

    send-to-layer: (item, name) ->
        set-keypath item, 'data.aecad.layer', name
        @add-layer name  # add the layer if it doesn't exist
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        layer.addChild item

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    _Line: (opts) ->
        new Line opts, @_scope

    hitTestAll: (point, opts={}) ->
        # Hit test all which circumvents the option overwrite problem of original
        # .hitTestAll method, uses normalized tolerance

        defaults = {+fill, +stroke, +segments, tolerance: 0}
        opts = defaults <<< opts
        opts.tolerance = opts.tolerance / @_scope.view.zoom
        @_scope.project.hitTestAll point, opts

    hitTest: ->
        # TODO: is this true? is it equivalent to the first hit of @hitTestAll! ?
        @hitTestAll ... .0
