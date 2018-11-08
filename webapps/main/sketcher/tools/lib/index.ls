require! 'aea/do-math': {mm2px}
require! 'aea'
require! '../../kernel': {PaperDraw}

export function getClass data
    name = data?aecad?type or data
    if name.match /^[a-zA-Z0-9_]+$/
        eval name
    else
        throw new Error "Who let the dogs out?"

export getAecad = (item) ->
    # Return aeCAD object
    try
        # TODO: remove try/catch part to speed up when this is stable
        type = item.data?aecad?type
        return new (getClass type) do
            name: name
            init: item
    catch
        console.error "getAecad Error: type was: ", type
        throw e


export find-comp = (name) !->
    {project} = new PaperDraw
    for project.layers
        for ..getItems()
            if ..data?aecad?name is name
                return getAecad ..
    return null

export class Container
    (parent) ->
        {Group, Path, Rectangle, PointText, Point, Shape, canvas, view, project} = new PaperDraw
        # parent: parent object or initialization data
        # if in {init: ...} format
        @pads = []
        init-with-data = no
        if parent and \init of parent
            init = parent.init
            parent = null
            if init
                init-with-data = yes
                #console.log "Container init:", init
                @g = init
                for @g.children
                    #console.log "has child: ", (getClass ..data)
                    type = ..data?aecad?type
                    @pads.push switch type
                    | \Container =>
                        new (getClass type)({init: ..})
                    | \Pad =>
                        new (getClass type) do
                            init:
                                parent: this
                                content: ..
                    |_ => throw new Error "What type is this? #{type}"


        unless init-with-data
            # create main container
            @g = new Group do
                applyMatrix: no
                parent: parent?g
            parent?add this

            @g.data =
                aecad:
                    type: @constructor.name

    position: ~
        -> @g.position
        (val) -> @g.position = val

    color: ~
        (val) ->
            for @pads
                ..color = val

    print-mode: (val) ->
        for @pads
            ..print-mode val

    add: (item) !->
        @pads.push item

    rotate: (angle) ->
        # rotate this item and inform children
        @rotation = angle
        @g.rotate angle
        for @pads
            ..rotated? angle

    rotated: (angle) ->
        for @pads
            ..rotated? angle

    mirror: (state) ->
        @g.scale -1, 1
        x = @g.bounds.center
        @g.rotate (180 + 2 * @rotation), @g.bounds.center
        @g.bounds.center = x  # this is interesting, I'd expect no need for this
        for @pads
            ..mirrored? state

    mirrored: (state) ->
        for @pads
            ..mirrored? state

export class Footprint extends Container
    (data) ->
        {Group, Path, Rectangle, PointText, Point, Shape, canvas, view, project} = new PaperDraw

        # data:
        #   name: required
        #   position: optional
        #   rotation: optional
        #   init: current drawing
        super {init: data.init}
        unless data.init
            # initialize from scratch
            @data =
                type: @constructor.name

            @data <<<< data
        else
            # initialize with provided data
            @data = data.init.data.aecad

        @g.data = aecad: @data

export class Pad
    (parent, opts) ->
        {Group, Path, Rectangle, PointText, Point, Shape, canvas, view, project} = new PaperDraw

        # opts:
        #     # Required
        #     pin
        #     width
        #     height

        init-with-data = no
        if parent and \init of parent
            init = parent.init
            parent = null
            if init
                init-with-data = yes
                #console.log "Pad init:", init
                @g = init.content
                @parent = init.parent
                for @g.children
                    # get cu, ttip etc.
                    part = ..data.aecad.part
                    @[part] = ..


        # declare Pad.left, Pad.top, ...
        for <[ left right top bottom center ]>
            Object.defineProperty @, .., do
                get: ~> @g.bounds[..]

        unless init-with-data
            @parent = parent
            @opts = opts

            if @opts.width and @opts.height
                geometry = \Rectangle
                dimensions =
                    x: @opts.width |> mm2px
                    y: @opts.height |> mm2px

                rect = new Rectangle do
                    from: [0, 0]
                    to: dimensions

                geo-params = {rectangle: dimensions}

            else if @opts.dia
                geometry = \Circle
                x = @opts.dia |> mm2px
                dimensions =
                    radius: x / 2
                    x: x
                    y: x

                rect = new Rectangle do
                    from: [0, 0]
                    to: [x, x]

                geo-params = {radius: dimensions.radius}


            aecad-data =
                type: @constructor.name

            aecad-data <<< @opts

            @g = new Group do
                position: rect.center
                parent: @parent.g
                data:
                    aecad: aecad-data
                applyMatrix: yes

            @parent.add this

            @cu = new Shape[geometry] geo-params <<< do
                rectangle: rect
                fillColor: 'purple'
                parent: @g
                stroke-width: 0
                data: aecad: part: \cu

            if @opts.drill
                @drill = new Path.Circle do
                    radius: (@opts.drill / 2) |> mm2px
                    fillColor: canvas.style.background
                    parent: @g
                    position: @cu.position
                    stroke-width: 0
                    data: aecad: part: \drill

            @ttip = new PointText do
                point: @cu.bounds.center
                content: @opts.pin
                fill-color: 'white'
                parent: @g
                font-size: 3
                position: @cu.bounds.center
                justification: 'center'
                data: aecad: part: \ttip

            @ttip.bounds.center = @cu.bounds.center


    position: ~
        -> @g.position
        (val) -> @g.position = val

    color: ~
        (val) ->
            @_color = val
            @cu.fillColor = @_color

    clone: (opts={}) ->
        new @constructor @parent, (@opts <<<< opts)

    print-mode: (val) ->
            @_print = val
            if @_print
                # switch to print mode
                @drill?.fillColor = \white
                @ttip.visible = false
                @cu.fillColor = \black
            else
                @drill?.fillColor = canvas.style.background
                @ttip.visible = true
                @cu.fillColor = @_color

    rotated: (angle) ->
        @rotation = angle
        @ttip.rotate -angle
        @ttip.bounds.center = @cu.bounds.center

    mirrored: (state) ->
        console.warn "TODO: set text rotation correctly"
