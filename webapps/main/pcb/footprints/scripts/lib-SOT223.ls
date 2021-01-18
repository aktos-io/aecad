# Sot223
#! requires DoublePinArray
add-class class SOT223 extends DoublePinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'c_'
            distance: 6.3mm
            left:
                start: 4
                pad:
                    width: 2.15mm
                    height: 3.8mm
                cols:
                    count: 1
            right:
                dir: '-y'
                pad:
                    width: 2mm
                    height: 1.5mm
                rows:
                    count: 3
                    interval: 2.3mm
            border:
                width: 3.5mm
                height: 6.5mm


add-class class SOT23 extends DoublePinArray
    (data, overrides) ->
        pad =
            width: 0.9mm
            height: 0.7mm

        super data, overrides `based-on` do
            name: 'c_'
            distance: 2mm
            left:
                start: 3
                pad: pad
                cols:
                    count: 1
            right:
                dir: '-y'
                pad: pad
                rows:
                    count: 2
                    interval: 1.9mm
            border:
                width: 1.43mm
                height: 3mm

#new SOT23


add-class class NPN extends SOT23
    @rev_NPN = 1
    (data, overrides) ->
        defaults =
            labels:
                1: 'b'
                2: 'e'
                3: 'c'
        super data, (defaults `aea.merge` overrides)

#new NPN

add-class class PNP extends NPN
