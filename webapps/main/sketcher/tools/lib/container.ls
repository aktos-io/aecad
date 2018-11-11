require! '../../kernel': {PaperDraw}
require! './component-base': {ComponentBase}
require! './get-aecad': {get-aecad}

export class Container extends ComponentBase
    (parent) ->
        super!
        {Group} = new PaperDraw

        @pads = []
        if @init-with-data arguments.0
            #console.log "Container init:", init
            data = that
            @g = data.item
            data.parent?add this # register to parent if provided
            for @g.children
                #console.log "has child"
                unless get-aecad .., this
                    @_loader ..
        else
            # create main container
            @g = new Group do
                applyMatrix: no
                parent: parent?g
                data:
                    aecad:
                        type: @constructor.name
            parent?add?(this)

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
        @add-data \rotation, angle
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


    get: (query) ->
        '''
        Collects sub query results and returns them
        '''
        res = []
        for pad in @pads
            res ++= pad.get query
        res
