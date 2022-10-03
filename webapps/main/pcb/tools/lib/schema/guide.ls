# deps
require! './lib': {combinations}
require! 'prelude-ls': {reverse}

export do
    guide-for: (ref, targets) ->
        guides = []
        for pads in (targets or [])
            for index til pads.length - 1
                line =
                    pads[index]
                    pads[index+1]

                if ref
                    unless ref.pin in line.map (.pin)
                        # unrelated pads, skip
                        continue
                    if line.1.g-pos.isClose ref.g-pos, 1
                        # correct the direction
                        line = reverse line
                guides.push @create-guide ...line
        return guides

    guide-all: ->
        @guide-for null, @netlist

    guide-unconnected: (opts={}) !->
        # Options: 
        # cached: (Boolean) Use previous calculation, do not re-calculate the connection states. 
        @chrono-start "guide-unconnected"
        @guide-for null, @get-unconnected-pads(opts)
        @chrono-log "guide-unconnected"

    get-unconnected-pads: (opts={}) -> 
        # Options: 
        # cached: (Boolean) Use previous calculation, do not re-calculate the connection states. 
        conn-states = if opts.cached and @_connection_states?
            @_connection_states
        else
            @calc-connection-states!
        unconnecteds = [o.unconnected-pads for i, o of conn-states]

    create-guide: (pad1, pad2, _opts={}) ->
        opts = {+selected} <<< _opts
        #console.log "Created guide for #{pad1.uname} -> #{pad2.uname}"
        return new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lightblue'
            stroke-width: 0.1
            selected: opts.selected
            data: {+guide, +tmp}

    clear-guides: ->
        for @scope.project.layers
            for ..getItems {-recursive} when ..data.guide
                ..remove!
