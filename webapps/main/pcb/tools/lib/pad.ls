require! '../../kernel': {PaperDraw}
require! './component-base': {ComponentBase}
require! 'aea/do-math': {mm2px, px2mm}
require! 'prelude-ls': {empty, sort-by}

/* -------------------------------------------------

Pad
    .side           : F.Cu/B.Cu
    .match-side     : [side] check if the pad is present on the given side
    .position       : in px
    .gpos           : global position
    .gbounds        : global bounds
    .pin            : fully qualified pin label (eg. "P.C1.gnd")
    .uname          : uniqe pin name (eg. "P.C1.gnd(5)")
    .label          : label seen on the pad (eg. "gnd")
    .num            : exact pin number in the footprint (eg. "5")
    .netid          : Net ID of the pad


/* ------------------------------------------------- */

export class Pad extends ComponentBase
    ->
        @_guides = []
        super ...

    create: (opts) ->
        # opts:
        #     # Required
        #     pin
        #     width
        #     height
        #
        {Path, Rectangle, PointText, Shape, canvas} = new PaperDraw
        # create object from scratch
        if opts.width and opts.height
            geometry = \Rectangle
            dimensions =
                x: opts.width |> mm2px
                y: opts.height |> mm2px

            if opts.centered
                rect = new Rectangle do
                    from: [-dimensions.x/2, -dimensions.y/2]
                    to: [+dimensions.x/2, +dimensions.y/2]
            else
                rect = new Rectangle do
                    from: [0,0]
                    to: [dimensions.x, dimensions.y]

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
            #point: @cu.bounds.center
            fill-color: 'white'
            # THIS DOESN'T ACTUALLY WORK: parent: @g
            font-size: 0.8
            #position: @cu.bounds.center
            justification: 'center'
            data: aecad: part: \ttip
        @ttip.parent = @g

        if opts.color
            @color = that

        
        if pos=opts.position
            if pos.x
                @position.x += pos.x |> mm2px
            if pos.y
                @position.y += pos.y |> mm2px
        
    pos-x: ~
        -> @position.x |> px2mm
        (val) -> @position.x = (val |> mm2px)

    pos-y: ~
        -> @position.y |> px2mm
        (val) -> @position.y = (val |> mm2px)

    finish: !->
        @ttip.content = @label 
        if @ttip.content # <= this checking is very important!
            # if tooltip has no content, then calculating aspect ratio
            # becomes Not-A-Number, which in turn breaks the app
            # TODO: Fix this bug in Paper.js by checking width and height of source
            # before actually calculating the overall ratio
            @ttip.fit-bounds @cu.bounds.scale 0.6

    color: ~
        (val) !->
            @_color = val
            @cu.fillColor = unless @drill
                @_color
            else
                'orange' # TODO: get "Edge" color for this

    side-match: (side) ->
        our-side = @owner.side or @side
        if side is our-side or @drill?
            return true
        #console.log "searching side (#{side}) doesn't match with ours: #{our-side}"
        return false

    print-mode: ({layers}, our-side) ->
        if layers
            # switch to print mode
            if @side
                our-side = that
            #console.log "side we are in: ", our-side
            if our-side in layers or @drill?
                # will be printed
                @drill
                    ..?fillColor = \white
                    ..?bounds.size = 0.5 |> mm2px
                    ..?bounds.center = @cu.bounds.center
                @cu.fillColor = \black
                @g.opacity = 1
            else
                # won't be printed
                @drill?.visible = no
                @cu.remove!
            @ttip.remove!
        else
            # switch back to design mode
            @drill?.fillColor = canvas.style.background
            @drill?.visible = yes
            @ttip.visible = true
            @cu.fillColor = @_color
            @cu.visible = yes

    rotated: (angle) ->
        @set-data \rotation, ((angle + (@get-data('rotation') or 0)) % 360)
        unless @get-data 'mirrored'
            angle = -angle
        @ttip.rotate angle
        @ttip.bounds.center = @cu.bounds.center

    mirrored: (scale-factor, rotation) !->
        @toggle-data 'mirrored'
        @ttip.scale ...scale-factor
        @ttip.rotate (180 - 2 * (rotation % 360)), @ttip.bounds.center

    cu-bounds: ~
        # Copper bounds
        ->
            # Workaround for getting global bounds of @g
            r = new @scope.Path.Rectangle rectangle: @cu.bounds
                ..rotate @grotation
                ..position = @gpos
            bounds = r.bounds.clone!
            r.remove!
            return bounds


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
            lookup-pins = [@label]
            unless @owner.disallow-pin-numbers
                lookup-pins.push "#{@num}"

            if "#{query.pin}" in lookup-pins 
                res.push this
        if \item of query
            # report matching items
            if query.item in [@g, @cu, @ttip, @drill].map((?.id)).filter((Boolean))
                res.push this
        res

    label: ~
        # Return pad label (eg. "Vin")
        ->
            label = @get-data 'label'
            x = "#{label or @num or ''}"
            @owner.set-data "_labels.#{@num}", x 
            x 

    num: ~
        # Return pad number (eg. 5) regardless of existence of @label
        -> @get-data 'pin'

    pin: ~
        # Get fully qualified pin label (eg. "P.C1.gnd")
        -> "#{@owner.name}.#{@label}"

    uname: ~
        # Unique display name in the project (eg. "P.C1.gnd(3)")
        -> "#{@pin}(#{@num})"

    netid: ~
        -> 
            _netid = @get-data('netid') or ''
            if @owner.type is \Trace 
                _netid = @owner.netid 

            return _netid 

        (val) -> @set-data 'netid', "#{val}"

    is-via: ~
        -> @owner.type is \Trace

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
        return npad

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
        | 'focus' =>
            side = args.0
            if @side-match args.0
                # our side is focused
                @g.opacity = 1
            else
                @g.opacity = @blur-opacity
        | 'export-gerber' => 
            coord-to-gerber = (-> (it * 1e5) |>  parse-int)
            x-pos = coord-to-gerber px2mm @gpos.x 
            mirror-offset = 200mm # FIXME: remove this offset properly
            y-pos = coord-to-gerber (mirror-offset - px2mm @gpos.y)

            gerber-data = (margin=0) ~> 
                if @data.dia 
                    # circular 
                    """
                    G04 #{@uname}*                          # comment 
                    # G04 Side is: #{@layer}.#{@side2}* 
                    %FSLAX35Y35*%                           # set number format to 3.5 for coordinates 
                    %MOMM*%                                 # set units to MM
                    %LPD*%                                  # Set the polarity to [D]ark

                    %ADD10C,#{@data.dia + 2 * margin}*%     # "Aperture Define D10 as Circle"

                    D10*                                    # Set the current tool (aperture) to D10
                    X#{x-pos}Y#{y-pos}D02*                  # Go to (D02) that coordinates
                    D03*                                    # Create a drawing with current (=D10) aperture

                    M02*                                    # End of file 
                    """
                else 
                    # rectangular 
                    [w, h] = [@data.width, @data.height]
                    if (@owner.data.rotation) %% 360 in [90, 270]
                        # FIXME: This is a quick and dirty hack for rotated pads
                        [w, h] = [h, w]
                    #console.log "Pad coord: #{@uname}: x:#{@gpos.x}, y:#{@gpos.y}"
                    """
                    G04 #{@uname}*                          # comment 
                    # G04 Side is: #{@layer}.#{@side2}* 
                    %FSLAX35Y35*%                           # set number format to 3.5 for coordinates
                    %MOMM*%                                 # set units to MM
                    %LPD*%                                  # Set the polarity to [D]ark

                    %ADD10R,#{w + margin}X#{h + margin}*%   # "Aperture Define D10 as Rectangle"

                    D10*                                    # Set the current tool (aperture) to D10
                    X#{x-pos}Y#{y-pos}D02*                  # Go to (D02) that coordinates
                    D03*                                    # Create a drawing with current (=D10) aperture

                    M02*                                    # End of file 
                    """ 

            # Add Copper layer 
            @gerber-reducer.append do
                layer: if @is-via then \Cu else @layer 
                side: if @drill or @is-via then null else @side2
                gerber: gerber-data!

            # Add Mask Layer 
            unless @is-via
                @gerber-reducer.append do
                    layer: \Mask 
                    side: if @drill then null else @side2
                    gerber: gerber-data(margin=0.2mm)

            # Add drill
            if @drill 
                @gerber-reducer.add-drill @data.drill, do
                    x: x-pos/1e5
                    y: y-pos/1e5
