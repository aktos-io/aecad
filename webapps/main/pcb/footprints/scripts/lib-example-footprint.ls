# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------

add-class class ExampleFootprint extends Footprint
    create: (data) ->
        pads =
            pad1:
                desc:
                    pin: 1
                    label: 'a'
                    width: 2mm
                    height: 3mm
                position:
                    x: 0mm
                    y: 0mm
            pad2:
                desc:
                    pin: 2
                    label: 'b'
                    width: 2mm
                    height: 3mm
                position:
                    x: 3mm
                    y: 0
            pad3:
                desc:
                    pin: 3
                    label: 'c'
                    width: 2mm
                    height: 3mm
                    drill: 1.2mm
                position:
                    x: 6mm
                    y: 0
            pad4:
                desc:
                    pin: 4
                    label: 'd'
                    dia: 3mm
                    drill: 1.2mm
                position:
                    x: 4mm
                    y: 6mm

        border =
            width: 9mm
            height: 8mm

        for i, pad of pads
            # initialize @iface
            @iface[pad.desc.pin] = pad.desc.label

            # create Pad objects
            new Pad ({parent: this} <<< pad.desc)
                ..pos-x += pad.position.x
                ..pos-y += pad.position.y

        @make-border {border}

#new ExampleFootprint!