export common =
    tools:
        '''
        _mm2px = ( / 25.4 * 96)
        _px2mm = (x) -> 1 / mm2px(x)

        mm2px = (x) ->
            _x = {}
            switch typeof x
            | 'object' =>
                for i of x
                    _x[i] = x[i] |> _mm2px
                _x
            |_ =>
                x |> _mm2px

        find-pin = (name, pin) !->
            _find = (item) !->
                if item.hasChildren!
                    for item.children
                        if _find ..
                            return that
                else if item.data?aecad?pin is pin
                    return item

            for project.layers
                for ..getItems()
                    if ..data?aecad?name is name
                        container = ..
                        pad = _find container
                        return {container, pad}

        '''

export scripts =
    "lib":
        '''
        g = new Group {opacity: 0.5}

        group = (parent) ->
            new Group do
                parent: parent or g
                applyMatrix: no

        pad = (pin-number, dimensions, parent) ->
            new Path.Rectangle do
                from: [0, 0]
                to: dimensions |> mm2px
                fillColor: 'yellow'
                parent: parent or g
                stroke-width: 0
                data:
                    aecad:
                        pin: pin-number

        #find-pin "c1", 5
        #    ..pad.selected = yes

        '''

    "LM 2576":
        '''
        to263 = (pin-labels) ->
            # From: http://www.ti.com/lit/ds/symlink/lm2576.pdf
            dimensions = d =
                H   : 14.17mm
                die : x:8mm     y:10.8mm
                pads: x:2.16mm  y:1.07mm
                pd  : 1.702

            p1 = pad 1, d.die
                ..data.aecad.label = pin-labels.0

            padg = group()
            for index, pin of [1 to 5]
                pad pin, d.pads, padg
                    ..position.y -= index * mm2px d.pd
                    ..data.aecad.label = pin-labels[index]

            padg.position =
                d.H |> mm2px
                p1.bounds.height / 2

        to263 <[ Vin Out Gnd Feedback on_off ]>
        '''

    'R1206':
        '''
        # From http://www.resistorguide.com/resistor-sizes-and-packages/
        r1206 =
            a: 1.6mm
            b: 0.9mm
            c: 2mm

        {a, b, c} = r1206

        p1 = pad b, a
        p2 = p1.clone!
            ..position.x += (c + b) |> mm2px

        '''


do -> 
    'lib_ComponentProxy':
        '''
        class ComponentProxy
            (@main) ~>
                @__handlers = {}
                for let key of @main
                    Object.defineProperty @, key, do
                        get: ~>
                            @main[key]

                        set: (val) ~>
                            if @__handlers[key]?
                                [err, res] = @__handlers[key] val
                                unless err
                                    @main[key] = res
                            else
                                @main[key] = val

            on-set: (prop, handler) ->
                @__handlers[prop] = handler


        x = pad 1, {x: 10, y: 20}
        console.log "hello there"
        y = new ComponentProxy x
        y.on-set 'position', (val) ->
            console.log "Doing MITM for position: ", val
            [null, val]
        y.position += [10, 10]
        '''
