require! './find-comp': {find-comp}
require! 'prelude-ls': {find}
require! '../../kernel': {PaperDraw}

export class Schematic
    @instance = null
    (netlist) ->
        # Make this class Singleton
        return @@instance if @@instance
        @@instance = this
        @scope = new PaperDraw
        @connections = []

        if netlist
            @load that

    load: (@netlist) !->
        # compile schematic
        @connections.length = 0
        for k, conn of @netlist
            # TODO: performance improvement:
            # use find-comp for each component only one time
            @connections.push <| conn
                .split /[,\s]+/
                .map (.split '.')
                .map (x) ->
                    comp = find-comp(x.0)
                    src: x.join '.'
                    c: comp
                    pad: comp.get {pin: x.1}

    guide-for: (src) ->
        for @connections when find (.src is src), ..
            @guide ..0.pad.0, ..1.pad.0

    guide: (pad1, pad2) ->
        new @scope.Path.Line do
            from: pad1.g-pos
            to: pad2.g-pos
            stroke-color: 'lime'
            selected: yes
            data: {+tmp}
