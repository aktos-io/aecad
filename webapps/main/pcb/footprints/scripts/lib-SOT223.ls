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

add-class class BC807_SOT23 extends PNP

add-class class BC640_SOT23 extends PNP
    (data, overrides) ->
        super data, overrides `based-on` do
            labels:
                1: 'e'
                2: 'c'
                3: 'b'

add-class class NMos extends SOT23
    @rev_NMos = 1
    (data, overrides) ->
        super data, overrides `based-on` do
            labels:
                1: 'g'
                2: 's'
                3: 'd'


add-class class IRLML2502 extends NMos

add-class class DPAK extends DoublePinArray
    # Reference: https://www.infineon.com/export/sites/default/en/product/packages/_images/09018a90800830a9.png_1448008138.png
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'c_'
            distance: 6.3mm
            left:
                start: 3
                pad:
                    width: 6.4mm
                    height: 5.8mm
                cols:
                    count: 1
            right:
                dir: '-y'
                pad:
                    width: 2.2mm
                    height: 1.2mm
                rows:
                    count: 2
                    interval: 2.28mm * 2
            border:
                width: 6.3mm + 3.2mm + 1.1mm + 1mm
                height: 6.8mm

#new DPAK

add-class class IRFR024 extends DPAK
    (data, overrides) ->
        super data, overrides `based-on` do
            labels:
                1: "g"
                2: "s"
                3: "d"

#new IRFR024

