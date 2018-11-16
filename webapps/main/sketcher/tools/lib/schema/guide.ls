# deps
require! './lib': {combinations}

export do
    guide-for: (src) ->
        guides = []
        for pads in @netlist
            for combinations [pads, pads]
                [f, s] = ..
                console.log "creating gude "
                guides.push @create-guide f, s
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
