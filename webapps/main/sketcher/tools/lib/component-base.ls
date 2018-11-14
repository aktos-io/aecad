require! 'dcs/lib/keypath': {get-keypath, set-keypath}
require! '../../kernel': {PaperDraw}

# basic methods that every component should have
export class ComponentBase
    ->
        @scope = new PaperDraw
        @ractive = @scope.ractive

        @resuming = @init-with-data arguments.0

    set-data: (keypath, value) ->
        set-keypath @g.data.aecad, keypath, value

    get-data: (keypath) ->
        get-keypath @g.data.aecad, keypath

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

    g-pos: ~
        # Global position
        ->
            # TODO: I really don't know why ".parent" part is needed. Find out why.
            @g.parent.localToGlobal @g.bounds.center

    name: ~
        -> @get-data \name
