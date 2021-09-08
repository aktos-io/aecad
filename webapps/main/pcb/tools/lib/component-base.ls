require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! '../../kernel': {PaperDraw}
require! '../../kernel/gerber-plotter': {GerberReducer}
require! './get-aecad': {get-aecad}
require! './get-class': {get-class}
require! 'aea': {merge, clone}
require! './lib': {prefix-keypath, get-rev}
require! './component-manager': {ComponentManager}
require! './schema': {SchemaManager}
require! 'prelude-ls': {find}



# Basic methods that every component should have
# -----------------------------------------------
export class ComponentBase
    (data, overrides) ->
        @scope = new PaperDraw
        @ractive = @scope.ractive
        @manager = new ComponentManager
            ..register this
        @_schema_manager = new SchemaManager
        @pads = []
        @_next_id = 1 # will be used for enumerating pads
        @blur-opacity = 0.2
        # declare Pad.left, Pad.top, ...
        for <[ left right top bottom center ]>
            Object.defineProperty @, .., do
                get: ~> @g.bounds[..]

        @gerber-reducer = new GerberReducer

        @overrides = overrides or {}
        if init=data?init
            # initialize by provided item (data)
            @resuming = yes     # flag for sub-classers
            if init.parent      # must be an aeCAD obect
                @parent = that
                    ..add this  # Register to parent

            @g = init.item

            for @g.children
                #console.log "has child"
                if ..data?.aecad?.part
                    # register as a regular drawing part
                    @[that] = ..
                else
                    # try to convert to aeCAD object
                    unless get-aecad .., this
                        # if failed, try to load by provided loader
                        @_loader ..
        else
            # create from scratch
            {Group} = new PaperDraw
            if data?parent
                @parent = data?.parent
                delete data.parent      # Prevent circular reference errors

            @g = new Group do
                applyMatrix: no         # Insert further items relatively positioned
                parent: @parent?g

            # Set type to implementor class' name
            @type = @@@name

            # Merge data with existing one
            @merge-data '.', data

            # Auto register to parent if provided
            @parent?.add this

            # Save creator class' rev information
            if rev = get-rev @@@
                #console.log "Creating a new #{@@@name}, registering rev: #{rev}"
                @set-data 'rev', rev

            # perform the actual drawing
            unless data?.silent
                try 
                    @create(@_data)
                catch 
                    throw new Error "#{@@@name}: #{e}"

        # do the post processing either after creation or rehydration
        @finish!

    finish: ->

    create: (data) ->
        # Footprint will be created at this step.

    remove: ->
        @g.remove!

    gcid: ~
        # a hack for getting current id
        -> @g.id

    type: ~
        -> @get-data 'type'
        (val) -> @set-data 'type', val

    set-data: (keypath, value) ->
        _keypath = prefix-keypath 'aecad', keypath
        set-keypath @g.data, _keypath, value

    get-data: (keypath) ->
        _keypath = prefix-keypath 'aecad', keypath
        get-keypath @g.data, _keypath

    toggle-data: (keypath) ->
        @set-data keypath, not @get-data keypath

    add-data: (keypath, value, fn) ->
        curr = (@get-data keypath) or 0 |> parse-int
        new-val = curr + value
        if typeof! fn is \Function
            new-val = fn(new-val)
        @set-data keypath, new-val

    merge-data: (keypath, value) ->
        if value and typeof! value is \Object
            curr = @get-data(keypath) or {}
            curr `merge` value
            @set-data keypath, curr

    send-to-layer: (layer-name) ->
        @g `@scope.send-to-layer` layer-name

    allow-duplicate-labels: ~
        -> @overrides.allow-duplicate-labels

    disallow-pin-numbers: ~
        -> @overrides.disallow-pin-numbers

    print-mode: (opts, our-side) ->
        # opts.layers: [Array] String array indicates which layers (sides)
        #         to be printed
        # our-side: The side which the first container object is
        #
        # see Container.print-mode for exact code
        #
        console.warn "Print mode requested but no custom method is provided."

    _loader: (item) ->
        # custom loader method for non-standard items
        console.warn "#{@@@name} has a stray item: How do we rehydrate this?:", item

    get: (query) ->
        console.error "NOT IMPLEMENTED: Requested a query: ", query

    position: ~
        -> @g.position
        (val) -> @g.position = val

    bounds: ~
        -> @g.bounds
        (val) -> @g.bounds = val

    grotation: ~
        ->
            (@get-data('rotation') or 0) % 360

    gbounds: ~
        # Global bounds
        ->
            # Workaround for getting global bounds of @g
            r = new @scope.Path.Rectangle rectangle: @g.bounds
                ..rotate @grotation
                ..position = @gpos
            bounds = r.bounds.clone!
            r.remove!
            return bounds

    selected: ~
        -> @g.selected
        (val) -> @g.selected = val

    g-pos: ~
        ->  # TODO: add deprecation message here
            @gpos

    gpos: ~
        # Global position
        ->
            # FIXME: I really don't know why ".parent" part is needed. Find out why.
            try 
                @g.parent.localToGlobal @g.bounds.center
            catch 
                debugger 
                throw e 

    name: ~
        -> @get-data \name
        (val) -> 
            console.log "Component #{@name} renamed to #{val}..."
            @set-data \name, val 

    owner: ~
        ->
            _owner = this
            _fuse = 100
            for i to _fuse 
                if _owner.parent
                    _owner = _owner.parent
                else
                    break
            if i is _fuse 
                throw new Error "Fuse activated here."
            return _owner

    nextid: ->
        @_next_id++

    pedigree: ~
        ->
            res = []
            l = @__proto__
            for to 100
                l = l.__proto__
                if l@@name is \Object
                    break
                res.push l
            {names: res.map (.@@name)}

    trigger: !->
        # trigger an event for children
        for @pads
            ..on ...arguments
        else
            @on ...arguments 

    on: !->
        # propagate the event to the children by default
        for @pads
            ..on ...arguments

    add-part: (part-name, item) ->
        # register given part (must be a child of @g, see @constructor)
        # as an aecad part. 
        set-keypath item.data, "aecad.part", part-name

    get-part: (part-name) -> 
        # returns PaperJS item 
        find (.data?aecad?part is part-name), @g.children

    schema: ~
        -> @_schema_manager.active

    tmp-marker: (point, opts={}) ->
        # will be used for debugging purposes
        console.warn "Placing a tmp marker to:", point, "opts: ", opts
        new @scope.Path.Circle {
            center: point
            data: {+tmp}
            radius: opts.r or opts.radius or 1
            fill-color: opts.color or 'yellow'
            opacity: 0.8
        }

    side: ~
        # eg. F.Cu, B.Cu
        -> 
            #TODO: Add: console.warn "Component.side will be deprecated soon. Use .side2 "
            @owner.get-data 'side' or @get-data \side

    layer: ~
        # returns: "Cu", "Mask" or null
        -> @side?.split '.' .1

    side2: ~
        # returns: "F", "B" or null 
        -> @side?.split '.' .0

    _data: ~
        # merged data of both instance data and pedigree classes' overwrites
        -> clone(@data) `merge` @overrides

    value: ~
        -> @_data.value

    data: ~
        -> @get-data('.') or {}

    upgrade: (opts={}) ->
        #console.log "curr data: ", @data
        /*
            data = clone(@data) `merge` opts
        */
        data = clone @data
        for k of data
            # only below properties are dynamically set, others
            # are from class definition. < FIXME: data shouldn't contain
            # properties from class definition, it should only contain instance
            # specific data
            if k in <[ name rotation side type value _labels ]>
                continue
            delete data[k]
        data `merge` opts
        data.labels = clone(data.labels or {}) `merge` (data._labels or {})
        comp = new (get-class data.type) data
        comp.g.position = @g.position
        @remove!
        @schema.compile!
        return comp
        #new @constructor @parent, (opts `merge` opts)
