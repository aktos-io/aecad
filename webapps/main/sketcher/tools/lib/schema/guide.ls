# deps
require! './lib': {combinations}

export do
    guide-for: (src) ->
        guides = []
        for pads in @netlist
            for index to pads.length
                console.log "creating guide: ", index
                break if index + 1 >= pads.length
                @create-guide pads[index], pads[index + 1]
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
