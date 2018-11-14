require! '../../kernel': {PaperDraw}
require! './component-base': {ComponentBase}
require! 'aea/do-math': {mm2px}

export class Pad extends ComponentBase
    (opts) ->
        {Group, Path, Rectangle, PointText, Shape, canvas} = new PaperDraw
        super ...
        # opts:
        #     # Required
        #     pin
        #     width
        #     height

        if @init-with-data arguments.0
            @g = that.item
            @parent = that.parent
            @parent.add this
            for @g.children
                # get cu, ttip etc.
                part = ..data.aecad.part
                @[part] = ..
        else
            # create object from scratch
            @parent = opts.parent
            @opts = opts
            try delete opts.parent

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
                content: @opts.label or @opts.pin
                fill-color: 'white'
                parent: @g
                font-size: 3
                position: @cu.bounds.center
                justification: 'center'
                data: aecad: part: \ttip

            @ttip.bounds.center = @cu.bounds.center

        # common operations
        # -----------------------------
        if @g.data.aecad.color
            @color = that

        # declare Pad.left, Pad.top, ...
        for <[ left right top bottom center ]>
            Object.defineProperty @, .., do
                get: ~> @g.bounds[..]

    color: ~
        (val) !->
            @_color = val
            @cu.fillColor = unless @drill
                @_color
            else
                'orange' # TODO: get "Edge" color for this

    clone: (opts={}) ->
        new @constructor @parent, (@opts <<<< opts)

    print-mode: (layers, our-side) ->
        if layers
            # switch to print mode
            if @get-data \side
                our-side = that
            #console.log "side we are in: ", our-side
            if our-side in layers or @drill?
                # will be printed
                @drill?.fillColor = \white
                @cu.fillColor = \black
            else
                # won't be printed
                @drill?.visible = no
                @cu.visible = no
            @ttip.visible = false
        else
            # switch back to design mode
            @drill?.fillColor = canvas.style.background
            @drill?.visible = yes
            @ttip.visible = true
            @cu.fillColor = @_color
            @cu.visible = yes

    rotated: (angle) ->
        @set-data \rotation, angle
        @ttip.rotate -angle
        @ttip.bounds.center = @cu.bounds.center

    mirrored: (scale-factor, rotation) !->
        console.warn "TODO: set text rotation correctly"
        @ttip.scale ...scale-factor
        @ttip.rotate (180 + 2 * rotation), @ttip.bounds.center

    selected: ~
        # TODO: Create a more beautiful selection shape
        (val) ->
            @cu.selected = val
        ->
            @cu.selected

    get: (query) ->
        res = []
        if \pin of query
            pin = "#{query.pin}"
            # if label exists, do not match with "pin"
            if @get-data 'label'
                #console.log "label found, checking given pin: '#{pin}' against my label: '#{that}'"
                if pin is that
                    res.push this
            else if pin is "#{@get-data 'pin'}"
                res.push this
        res
