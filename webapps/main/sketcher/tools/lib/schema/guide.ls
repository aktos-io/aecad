# deps
require! './lib': {combinations}
require! 'prelude-ls': {reverse}

export do
    guide-for: (ref) ->
        guides = []
        for pads in @netlist
            for index til pads.length - 1
                line =
                    pads[index]
                    pads[index+1]

                if ref
                    unless ref.pin in line.map (.pin)
                        # unrelated pads, skip
                        continue
                    if line.1.g-pos is ref.g-pos
                        # correct the direction
                        line = reverse line
                guides.push @create-guide ...line
        return guides

    guide-all: ->
        @guide-for!

    create-guide: (pad1, pad2) ->
        console.log "Created guide for #{pad1.uname} -> #{pad2.uname}"
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
