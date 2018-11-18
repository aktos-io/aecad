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
            line.segments[s - i].remove!

    end: ->
        if @line
            # remove moving point
            @line.removeSegment (@line.segments.length - 1)
            if @corr-point
                @line.removeSegment (@line.segments.length - 1)
                @corr-point = null
            @line.selected = no

            if @line.segments.length is 1
                @line.remove!

            @reduce @line

        unless @g.hasChildren()
            console.log "empty trace, removing"
            @g.remove!
        else
            #@g.bounds.selected = true
            void

        @line = null
        @removed-last-segment = null
        @remove-helpers!
        @vias.length = 0

        @schema?.clear-guides!
        console.log "Trace ended."
