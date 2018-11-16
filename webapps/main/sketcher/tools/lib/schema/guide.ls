# global imports
require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
}

# deps
require! './deps': {
    find-comp, PaperDraw, text2arr, get-class, get-aecad
}

export do
    guide-for: (src) ->
        guides = []
        for node in @connections
            if src
                # Only create a specific guide for "src", skip the others
                if src not in [..src for node]
                    continue
                console.log "Creating guide for #{src}"
            if node.length < 2
                console.warn "Connection has very few nodes, skipping guiding: ", node
                continue

            for combinations [node, node], (.src)
                [f, s] = ..
                if src in ..map (.src)
                    continue
                console.log "creating gude #{f.src} -> #{s.src} (#{f.pad.0.g-pos} -> #{s.pad.0.g-pos})"
                guides.push @create-guide f.pad.0, s.pad.0
        return guides

    guide-all: ->
        @guide-for!

    create-guide: (pad1, pad2) ->
        new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lime'
            stroke-width: 0.1
            selected: yes
            data: {+tmp, +guide}

    clear-guides: ->
        for @scope.project.layers
            for ..getItems {-recursive} when ..data.tmp and ..data.guide
                ..remove!
