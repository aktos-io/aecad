require! 'prelude-ls': {empty, abs}

is-close = (v1, v2, tolerance=0.01) ->
    abs(v1 - v2) < tolerance


export do
    reduce: (line) !->
        to-be-removed = []
        last-index = line.segments.length - 1
        for i in [til last-index]
            if line.segments[i].point.isClose line.segments[i + 1].point, 1
                seg-index = i
                if seg-index is 0
                    console.log "we won't reduce first segment!"
                    if seg-index + 1 is last-index
                        console.log "...but we don't have a choice as segment index:", last-index
                    else
                        seg-index += 1
                if seg-index is last-index
                    console.log "we won't reduce last segment!"
                    if seg-index <= 1
                        console.log "...but we don't have a choice as segment index:", last-index
                    else
                        seg-index -= 1
                to-be-removed.push seg-index
        for i, s of to-be-removed
            console.log "Reducing the line segments."
            line.segments[s - i].remove!

    end: (pad) ->
        if @line
            # remove moving point
            @line.removeSegment (@line.segments.length - 1)
            if @corr-point
                @line.removeSegment (@line.segments.length - 1)
                @corr-point = null
            @line.selected = no

            if @line.segments.length is 1
                @line.remove!

            if pad and @line
                snap = pad.gpos
                # properly snap to target

                # remove redundant segments inside pad
                while @line.segments.length >= 2
                    if @line.segments[*-2].point.is-inside pad.gbounds
                        @line.removeSegment (@line.segments.length - 1)
                    else
                        break

                if @line.segments.length >= 3
                    mp = @line.segments[*-3].point # mate point
                    pp = @line.segments[*-2].point # previous point
                    lp = @line.segments[*-1].point # last point

                    lline = @scope._Line lp, pp
                    pline = @scope._Line pp, mp

                    lline.through snap
                    if lline.intersect pline
                        pp.set that
                        lp.set snap
                    else
                        debugger

            @reduce @line


        if empty @g.children or not @netid
            console.warn "empty/unused trace, removing"
            @g.remove!
        else
            #@g.bounds.selected = true
            void

        @line = null
        @removed-last-segment = null
        @remove-helpers!
        @vias.length = 0

        @clear-guides!

        @ractive.fire \calcUnconnected
        console.log "................Trace ended..................."
        if typeof! @on-end is \Function
            @on-end!
