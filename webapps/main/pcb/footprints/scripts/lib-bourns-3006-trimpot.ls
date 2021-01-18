# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------

add-class class Trimpot_Bourns_3006P extends Footprint
    '''
    Electrical Properties:

    1 ~~~~~~ 3
        ^--2
    '''
    @rev_Trimpot_Bourns_3006P = 1       # <- Use @rev_{CLASS_NAME} to upgrade the components in place.

    create: (data) ->
        dia = 1.2mm
        drill = 0.6mm
        body-length = 19.2mm
        body-height = 5mm
        #
        #            ,- t(op)
        # [ 1 2 3 ]=
        # l       r  ^- b(ottom)
        #
        d13x = 12.7mm # distance from 1 to 3, x direction
        d23x = 5.08mm
        d3rx = 3.3mm

        d23y = 2.54mm
        d3by = 1.4mm
        d13y = 0mm

        # calculated values
        dl1x = body-length - (d13x + d3rx)
        dt1y = body-height - (d13y + d3by)

        pads =
            pin1:
                desc: {pin: 1, dia, drill}
                position:
                    x: dl1x
                    y: dt1y
            pin2:
                desc: {pin: 2, dia, drill}
                position:
                    x: dl1x + d13x - d23x
                    y: dt1y + d13y - d23y
            pin3:
                desc: {pin: 3, dia, drill}
                position:
                    x: dl1x + d13x
                    y: dt1y + d13y

        border =
            body:
                width: body-length
                height: body-height
                centered: no

            screw:
                width: 0.8mm
                height: 2.4mm
                centered: no
                offset-x:~ -> border.body.width
                offset-y:~ -> border.body.height/2 - @height/2

        for i, pad of pads
            # initialize iface
            @iface-add pad.desc.pin, pad.desc.label

            # create Pad objects
            new Pad ({parent: this} <<< pad.desc)
                ..pos-x += pad.position.x
                ..pos-y += pad.position.y

        for name, data of border
            @make-border {border: data}

        # We assumed to view from top. However, all
        # dimensions were defined from bottom.
        @mirror!

#new Trimpot_Bourns_3006P!