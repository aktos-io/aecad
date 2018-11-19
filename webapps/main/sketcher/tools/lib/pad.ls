require! '../../kernel': {PaperDraw}
require! './component-base': {ComponentBase}
require! 'aea/do-math': {mm2px}
require! 'prelude-ls': {empty, sort-by}

export class Pad extends ComponentBase
    (opts) ->
        # opts:
        #     # Required
        #     pin
        #     width
        #     height
        #
        {Path, Rectangle, PointText, Shape, canvas} = new PaperDraw
        super ...
        unless @resuming
            # create object from scratch
            if opts.width and opts.height
                geometry = \Rectangle
                dimensions =
                    x: opts.width |> mm2px
                    y: opts.height |> mm2px

                rect = new Rectangle do
                    from: [0, 0]
                    to: dimensions

                geo-params = {rectangle: dimensions}

            else if opts.dia
                geometry = \Circle
                x = opts.dia |> mm2px
                dimensions =
                    radius: x / 2
                    x: x
                    y: x

                rect = new Rectangle do
                    from: [0, 0]
                    to: [x, x]

                geo-params = {radius: dimensions.radius}

            # TODO: Are those necessary?
            @g.position = rect.center
            @g.applyMatrix = true

            @cu = new Shape[geometry] geo-params <<< do
                rectangle: rect
                fillColor: 'purple'
                parent: @g
                stroke-width: 0
                data: aecad: part: \cu

            if opts.drill
                @drill = new Path.Circle do
                    radius: (opts.drill / 2) |> mm2px
                    fillColor: canvas.style.background
                    parent: @g
                    position: @cu.position
                    stroke-width: 0
                    data: aecad: part: \drill

            @ttip = new PointText do
                point: @cu.bounds.center
                content: opts.label or opts.pin
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

        @_guides = []

    color: ~
        (val) !->
            @_color = val
            @cu.fillColor = unless @drill
                @_color
            else
                'orange' # TODO: get "Edge" color for this

    /*
    clone: (opts={}) ->
        new @constructor @parent, (opts <<<< opts)
    */

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
        unless @get-data 'mirrored'
            angle = -angle
        @ttip.rotate angle
        @ttip.bounds.center = @cu.bounds.center

    mirrored: (scale-factor, rotation) !->
        console.warn "TODO: set text rotation correctly"
        @toggle-data 'mirrored'
        @ttip.scale ...scale-factor
        @ttip.rotate (180 - 2 * (rotation % 360)), @ttip.bounds.center

    selected: ~
        # TODO: Create a more beautiful selection shape
        (val) ->
            @g.selected = false
            @cu.selected = val
        ->
            @cu.selected

    get: (query) ->
        res = []
        if \pin of query
            if "#{query.pin}" is @label
                res.push this
        if \item of query
            # report matching items
            if query.item in [@g, @cu, @ttip, @drill].map((?.id)).filter((Boolean))
                res.push this
        res

    label: ~
        ->
            label = @get-data 'label'
            "#{label or @num}"

    pin: ~
        # Get fully qualified pin label
        -> "#{@owner.name}.#{@label}"

    num: ~
        # Return pin number.
        -> @get-data 'pin'

    uname: ~
        # Unique display name
        -> "#{@pin}(#{@num})"

    net: ~
        (val) ->
            # TODO: assign relevant net on schema.compile! time
        ->
            unless @_net
                @_net = [] # return empty list by default
                if @schema
                    :search for net in @schema.netlist
                        for net when ..uname is @uname
                            @_net = net
                            break search
            return @_net

    targets: ~
        ->
            # target connections: same as @net, but excluding `this` and
            # the pads that has same visible label inside the same @owner
            res = []
            for @net when ..uname isnt @uname
                # skip to this component's same labels
                if ..pin is @pin
                    #console.warn "Skipping connection for: ", ..pin, ..uname
                    continue
                res.push ..
            res

    connections: ~
        -> [[this, ..] for @targets]

    create-guides: (count) ->
        if @schema and empty @_guides
            sorted = @targets
            for i til sorted.length
                break if count? and count is i
                @_guides.push @schema.create-guide this, sorted[i], {-selected}
        @_guides

    nearest-target: (point) ->
        unless point
            point = @gpos
        npad = null
        min-dist = -1
        for @targets
            dist = ..gpos.subtract point .length
            if min-dist < 0 or dist < min-dist
                min-dist = dist
                npad = ..
        console.log "Nearest pad: ", npad.uname, "cid:", npad.cid
        return npad

    gpos: ~
        -> @g-pos

    guides: ~
        -> @_guides

    on-move: (disp, opts) ->
        @create-guides!
        for @guides
            ..first-segment.point = @g-pos

    on: (event, ...args) ->
        switch event
        | 'create-guides' =>
            @create-guides!
        | 'clear-guides' =>
            @schema?clear-guides!
