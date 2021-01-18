# TO263 footprint
#
#! requires DoublePinArray
# ---------------------------

dimensions =
    # See http://www.ti.com/lit/ds/symlink/lm2576.pdf
    to263:
        H   : 14.17mm
        die : x:8mm     y:10.8mm
        pads: x:2.16mm  y:1.07mm
        pd  : 1.702

add-class class TO263 extends DoublePinArray
    (data, overrides) ->
        {H, die, pads, pd} = dimensions.to263
        super data, overrides `based-on` do
            name: 'c_'
            distance: H - die.x/2
            left:
                start: 6
                pad:
                    width: die.x
                    height: die.y
                cols:
                    count: 1
            right:
                dir: '-y'
                pad:
                    width: pads.x
                    height: pads.y
                rows:
                    count: 5
                    interval: pd

#new TO263
