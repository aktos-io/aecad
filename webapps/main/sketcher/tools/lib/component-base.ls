require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! '../../kernel': {PaperDraw}
require! './get-aecad': {get-aecad}
require! 'aea': {merge}
require! './lib': {prefix-keypath}
require! './component-manager': {ComponentManager}


# basic methods that every component should have
export class ComponentBase
    (data) ->
        @scope = new PaperDraw
        @ractive = @scope.ractive
        @manager = new ComponentManager
            ..register this
        @pads = []
        if @init-with-data arguments.0
            # initialize by provided item
            @resuming = yes
            #console.log "Container init:", init
            data = that
            @g = data.item
            if data.parent
                # parent must be an aeCAD obect
                @parent = that
                    ..add this # register to parent
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
                delete data.parent # Prevent circular reference errors

            @g = new Group do
                applyMatrix: no # Insert further items relatively positioned
                parent: @parent?g

            @set-data 'type', @@@name
            if data
                @merge-data '.', that
            @parent?.add this # Auto register to parent if provided
            @set-version!

        @_next_id = 1 # will be used for enumerating pads

    _loader: (item) ->
        console.warn "How do we load the item in #{@@@name}: ", item

    set-version: ->
        /* Gets version from @rev_ClassName property of leaf class */
        version = @@@["rev_#{@@@name}"]
        if version
            console.log "Creating a new #{@@@name}, registering version: #{version}"
            @set-data 'version', version

    set-data: (keypath, value) ->
        _keypath = prefix-keypath 'aecad', keypath
        console.log "Setting keypath: #{_keypath} to value: ", value
        set-keypath @g.data, _keypath, value

    get-data: (keypath) ->
        _keypath = prefix-keypath 'aecad', keypath
        get-keypath @g.data, _keypath

    toggle-data: (keypath) ->
        @set-data keypath, not @get-data keypath

    add-data: (keypath, value) ->
        curr = (@get-data keypath) or 0 |> parse-int
        @set-data keypath, curr + value

    merge-data: (keypath, value) ->
        curr = @get-data(keypath) or {}
        curr `merge` value
        @set-data keypath, curr

    send-to-layer: (layer-name) ->
        @g `@scope.send-to-layer` layer-name

    init-with-data: (first-arg) ->
        # detect if the component is initialized with
        # initialization data or being created from scratch
        #
        # Format:
        #   {
        #     init:
        #       item: Paper.js item
        #       parent: parent Component (optional)
        #   }
        if first-arg and \init of first-arg
            return first-arg.init

    print-mode: (layers, our-side) ->
        # layers: [Array] String array indicates which layers (sides)
        #         to be printed
        # our-side: The side which the first container object is
        #
        # see Container.print-mode for exact code
        #
        console.warn "Print mode requested but no custom method is provided."

    _loader: (item) ->
        # loader method for non-aecad objects
        console.warn "Item is not aeCAD object, how do we load this:", item

    get: (query) ->
        console.warn "NOT IMPLEMENTED: Requested a query: ", query

    position: ~
        -> @g.position
        (val) -> @g.position = val

    bounds: ~
        -> @g.bounds
        (val) -> @g.bounds = val

    selected: ~
        -> @g.selected
        (val) -> @g.selected = val

    g-pos: ~
        # Global position
        ->
            # TODO: I really don't know why ".parent" part is needed. Find out why.
            @g.parent.localToGlobal @g.bounds.center

    name: ~
        -> @get-data \name

    owner: ~
        ->
            _owner = this
            for to 100
                if _owner.parent
                    _owner = _owner.parent
                else
                    break
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

    on: !->
        # propagate the event to the children by default
        for @pads
            ..on ...arguments
