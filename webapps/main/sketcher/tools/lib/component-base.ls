require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! '../../kernel': {PaperDraw}

export class ComponentManager
    @instance = null
    ->
        # Make this class Singleton
        # ------------------------------
        return @@instance if @@instance
        @@instance = this
        # ------------------------------
        @cid = 1

    register: (component) ->
        # assign unique id only
        component.cid = @cid++  # component-id


# basic methods that every component should have
export class ComponentBase
    ->
        @scope = new PaperDraw
        @ractive = @scope.ractive
        @manager = new ComponentManager
            ..register this
        @resuming = @init-with-data arguments.0
        unless @resuming
            <~ sleep 10ms # ensure to run after end of constructor
            @set-version!
        @_next_id = 1 # will be used for enumerating pads

    set-version: ->
        /* Gets version from @rev_ClassName property of leaf class */
        version = @@@["rev_#{@@@name}"]
        if version
            console.log "Creating a new #{@@@name}, registering version: #{version}"
            @set-data 'version', version

    set-data: (keypath, value) ->
        set-keypath @g.data.aecad, keypath, value

    get-data: (keypath) ->
        get-keypath @g.data.aecad, keypath

    toggle-data: (keypath) ->
        @set-data keypath, not @get-data keypath

    add-data: (keypath, value) ->
        curr = (@get-data keypath) or 0 |> parse-int
        set-keypath @g.data.aecad, keypath, curr + value

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
