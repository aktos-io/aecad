require! '../../kernel': {PaperDraw}
require! './component-base': {ComponentBase}
require! './get-class': {get-class}

export class Container extends ComponentBase
    (parent) ->
        super!
        {Group, Path, Rectangle, PointText, Point, Shape, canvas, view, project, ractive} = new PaperDraw
        @ractive = ractive
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

    print-mode: (...args) ->
        if @get-data \side
            args.push that
        for @pads
            ..print-mode ...args

    add: (item) !->
        @pads.push item

    rotate: (angle) ->
        # rotate this item and inform children
        @set-data \rotation, angle
        @g.rotate angle
        for @pads
            ..rotated? angle

    rotated: (angle) ->
        # send rotate signal to children
        for @pads
            ..rotated? angle

    mirror: ->
        scale-factor = switch @get-data \symmetryAxis
        | 'x' => [-1, 1]
        |_ => [1, -1]
        console.log "scale factor is: ", scale-factor
        @g.scale ...scale-factor
        x = @g.bounds.center
        rotation = @get-data('rotation') or 0
        @g.rotate (180 + 2 * rotation), @g.bounds.center
        @g.bounds.center = x  # this is interesting, I'd expect no need for this
        for @pads
            ..mirrored? scale-factor, rotation

    mirrored: !->
        # send mirror signal to children
        for @pads
            ..mirrored? ...arguments

    set-side: (curr-side) !->
        # Side would be either 'Front' or 'Back'
        prev-side = @get-data \side
        #console.log "prev: #{prev-side}, curr: #{curr-side}"
        if prev-side isnt curr-side
            # Side is changed
            @set-data \side, curr-side
            # decide physical side for mirroring
            prev-phy = (try prev-side.split '.' .0) or 'F' # F or B (Front or Back)
            curr-phy = curr-side.split '.' .0 # F or B
            if prev-phy isnt curr-phy
                #console.log "back side, mirroring..."
                @mirror!
            layer-color = @ractive.get "layers.#{Ractive.escapeKey curr-side}" .color
            #console.log "color of #{curr-side} is #{layer-color}"
            @color = layer-color
