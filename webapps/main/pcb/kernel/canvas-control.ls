require! 'prelude-ls': {flatten, sort-by, reverse, empty, keys, compact, filter}
require! './line': {Line}
require! 'dcs/lib/keypath': {get-keypath, set-keypath}

# TODO: move get-aecad.ls here
require! '../tools/lib/get-aecad': {get-aecad}

export canvas-control =
    get-top-item: (item) ->
        if @ractive.get \selectGroup
            # select the top level group
            _fuse = 100
            for i in  [to _fuse]
                if item.parent.getClassName! is \Layer
                    break
                item = item.parent
            if i is _fuse 
                throw new Error "Fuse activated for get-top-item!"
            item
        else
            item

    get-bounds: (items=[]) ->
        # returns overall bounds        
        if empty items
            items = flatten [..getItems! for @project.layers]
        #console.log "Calculating bounds of items:", items 
        bounds = items.reduce ((bbox, item) ->
            switch item.getClassName! 
            | \Rectangle => 
                _bounds = item
            | \PointText => 
                # skip PointText
                return bbox
            |_ => 
                _bounds = item.bounds 

            return unless bbox
                _bounds
            else
                bbox.unite _bounds
            ), null
        #console.log "...bounds: #{bounds?.width}, #{bounds?.height}"
        return bounds

    cursor: (name) ->
        @prev-cursor = prev = @canvas.style.cursor
        unless name is prev
            console.log "Cursor is set from #{prev} to #{name}"
            @canvas.style.cursor = name
        prev

    default-cursor: (name) ->
        @_dcursor = name
        if @_dcursor0 isnt @_dcursor
            @_dcursor0 = @_dcursor
            # set a new cursor, immediately switch to it
            @cursor(@_dcursor)

    restore-cursor: ->
        @cursor(@prev-cursor)

    clean-tmp: ->
        for @get-all! when ..data?tmp
            ..remove!

    get-all: ->
        # returns all items
        flatten [..getItems! for @project.layers]

    search: (opts) ->
        items = []
        make-flatten = (item, parent=[]) ->
            r = []
            parent.push item.id
            keypath = JSON.parse JSON.stringify parent
            r.push {item, keypath}
            if item.hasChildren!
                for child in item.children
                    r ++= make-flatten child, keypath
            return r
        for layer in @project.layers
            items ++= make-flatten layer
        items |> sort-by (.keypath.length) |> reverse

    explode: (opts, items) ->
        exploded-items = []
        debugger

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
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        if layer
            that.activate!
        else
            layer = new @Layer!
                ..name = name
            @ractive.set "project.layers.#{Ractive.escapeKey name}", layer
        @ractive.set \activeLayer, name
        layer

    remove-layer: (name) ->
        console.log "Removing layer: #{name}"
        @project.layers[name].remove!
        try @ractive.delete 'project.layers', name

    clear-canvas: ->
        # clears all layers by properly removing @ractive references
        for @project.layers 
            ..remove-children!
        @ractive.delete 'project', 'layers'
        @ractive.set 'project.layers', {}

    register-layers: -> 
        for @project.layers when ..name 
            @ractive.set "project.layers.#{Ractive.escapeKey ..name}", ..

    send-to-layer: (item, name) ->
        #set-keypath item, 'data.aecad.side', name # DO NOT DO THAT, LEAVE THIS TO COMPONENT
        @add-layer name  # add the layer if it doesn't exist
        layer = @ractive.get "project.layers.#{Ractive.escapeKey name}"
        layer.addChild item

    add-tool: (name, tool) ->
        @tools[name] = tool

    get-tool: (name) ->
        @tools[name]

    _Line: (opts, p2) ->
        if p2
            opts = {p1: opts, p2}
        new Line opts, @_scope

    hitTestAll: (point, opts={}) ->
        # Hit test all which circumvents the option overwrite problem of original
        # .hitTestAll method, plus adds below options
        /*
            opts:
                ...inherits Paper.js opts, overwrites are as follows:

                tolerance   : normalized tolerance (regarding to zoom)
                normalize   : [Bool, default: true] Use normalized tolerance
                aecad       : [Bool, default: true] Include aeCAD objects if possible
                exclude-tmp : [Bool, default: true] Exclude items whose "data.tmp is true"
                exclude     : [Array of Items] Exclude list that hit result will ignore it and its children.
                filter      : Filter function. Return `false` to exclude the `hit` from the results

            Returns:
                Array of hits, where every hit includes:

                    Paperjs_Hit_Result <<< additional =
                        aecad:
                            ae-obj: aeCAD object that corresponds to hit.item
                            parent: Parent aeCAD object
        */
        defaults = {
            +fill, +stroke, +segments, tolerance: 0,
            +aecad, +normalize, +exclude-tmp
        }
        opts = defaults <<< opts
        if opts.normalize
            opts.tolerance = opts.tolerance / @_scope.view.zoom
        _hits = @_scope.project.hitTestAll point, opts
        hits = []
        :outer for hit in _hits
            # exclude temporary objects
            if opts.exclude-tmp
                continue if hit.item.data?tmp

            # exclude provided items
            if opts.exclude
                for compact flatten [that] when hit.item.isDescendant(..) or hit.item.id is ..id
                    continue outer

            # add aeCAD objects
            if opts.aecad
                hit.aeobj = get-aecad hit.item

            # Apply filter
            if opts.filter
                unless opts.filter(hit)
                    continue

            hits.push hit
        hits

    hitTest: ->
        # TODO: is this true? is it equivalent to the first hit of @hitTestAll! ?
        @hitTestAll ...arguments .0
