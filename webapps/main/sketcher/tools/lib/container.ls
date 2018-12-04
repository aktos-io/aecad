require! '../../kernel': {PaperDraw}
require! './component-base': {ComponentBase}
require! './get-aecad': {get-aecad}
require! 'prelude-ls': {find}

export class Container extends ComponentBase
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
        if find (.cid is item.cid), @pads
            throw new Error "Tried to add duplicate child, check: #{item@@name} or #{item.pedigree.names.join ', '}."
        else
            @pads.push item

    rotate: (angle, opts={}) ->
        # rotate this item and inform children
        @add-data \rotation, angle, (% 360)
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

    side: ~
        -> @get-data \side
        (val) -> @set-data \side, val

    set-side: (curr-side) !->
        # Side would be either 'F.*' for Front or 'B.*' for Back
        prev-side = @side
        #console.log "prev: #{prev-side}, curr: #{curr-side}"
        if prev-side isnt curr-side
            # Side is changed
            @side = curr-side
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
        Collect sub query results and return them
        '''
        res = []
        for pad in @pads
            res ++= pad.get query

        # Precaution for alpha stage of aeCAD
        for i1, r1 of res
            for i2, r2 of res when i2 > i1
                if r1.uname is r2.uname
                    console.error "..........we are reporting duplicate pads!", (res.map (.uname) .join ', ')
                    console.log r1, r2
        # end of precaution
        res

    on-move: ->
        for @pads
            ..on-move ...arguments
