# This is a work in progress
# ---------------------------------
/*

Example footprint template

*/

resolve = (_pads, _pad) ->
    unless _pad
        return {}
    pads = aea.clone _pads
    pad = aea.clone _pad

    #console.log "resolving: ", pad
    BASE = pad.is
    if BASE
        #console.log "pad depends: ", that, pads[that]
        delete pad["is"]
        pad = aea.merge pads[that], pad

    for dir, pos of (pad.position or {})
        if typeof! pos is \String
            # @.foo means pads.BASE.foo
            # TODO: throw error if pad.opts.is is null
            pos = pos.replace /^@\./, "pads.#{BASE}."
            # @bar.baz means pads.bar.baz
            pos = pos.replace /^@/, 'pads.'

        pad.position[dir] = pos

    if pad.is
        # base also depends on another one
        #console.log "...where #{BASE} depends some other: ", pad.is
        base = resolve _pads, _pads[pad.is]
        delete pad["is"]
        pad = aea.merge base, pad

    return pad

# Footprint is effectively a Group item
class Footprint
    (data) ->
        # create main container
        @g = new Group do
            applyMatrix: no
            data:
                aecad:
                    type: \Footprint

        /*
        @pads = {}
        for pad, params of data.pads
            base = getBase data.pads, params.is
            #console.log "initializing pad: #{pad} base: ", base
            @pads[pad] = new Pad @g, (base <<<< params)
        */

        @_data = {} # resolved data
        for name, pad of data.pads
            merged = resolve data.pads, pad
            @_data[name] = merged
            console.log "Resolved: #{name}:", merged
            #@pads[pad] = new Pad @g, merged


        # set positions
        /*
         * x, y (center coordinates of bounds)
         * top, bottom, left, right
         *
         */
        /*
        for name, pad of data.pads
            console.log "#{name} position: "
            for dir, pos of (pad.opts.position or {})
                # @.foo means pads.base.foo
                # TODO: throw error if pad.opts.is is null
                pos = pos.replace /^@\./, "pads.#{pad.opts.is}."
                # @bar.baz means pads.bar.baz
                pos = pos.replace /^@/, 'pads.'
                console.log "...#{dir} pos: ", pos
        */



    position: ~
        -> @g.position
        (val) -> @g.position = val

    color: ~
        (val) ->
            for k, pad of @pads
                pad.color = val


class Pad
    (parent, @opts) ->
        # opts:
        #     width
        #     height

        dimensions =
            x: @opts.width
            y: @opts.height

        rect = new Rectangle do
            from: [0, 0]
            to: dimensions |> mm2px

        @g = new Group do
            position: rect.center
            parent: parent
            data:
                aecad:
                    pin: opts.pin
            applyMatrix: yes

        @cu = new Path.Rectangle do
            rectangle: rect
            fillColor: 'purple'
            parent: @g
            stroke-width: 0

        @ttip = new PointText do
            point: @cu.bounds.center
            content: @opts.pin
            fill-color: 'white'
            parent: @g
            font-size: 3
            position: @cu.bounds.center

        # declare Pad.left, Pad.top, ...
        for <[ left right top bottom center ]>
            Object.defineProperty @, .., do
                get: ~> @g.bounds[..]

    position: ~
        -> @g.position
        (val) -> @g.position = val

    color: ~
        (val) -> @cu.fillColor = val


fp = new Footprint do

pad1 = new Pad fp, do
    width: 5
    height: 3


fp.color = 'red'
