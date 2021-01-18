#! requires QuadPinArray

add-class class LQFP48 extends QuadPinArray
    (data, overrides) ->
        pin-per-side = 12
        pad =
            width: 1.2mm
            height: 0.3mm
        pin-interval = 0.5mm

        super data, overrides `based-on` do
            name: 'c_'
            distance: 8.5mm
            left:
                start: 1
                dir: 'y'
                pad: pad
                rows:
                    count: pin-per-side
                    interval: pin-interval
            bottom:
                start: 1 + (pin-per-side * 1)
                pad: pad
                dir: '-y'
                rows:
                    count: pin-per-side
                    interval: pin-interval
            right:
                start: 1 + (pin-per-side * 2)
                pad: pad
                dir: '-y'
                rows:
                    count: pin-per-side
                    interval: pin-interval
            top:
                start: 1 + (pin-per-side * 3)
                dir: 'y'
                pad: pad
                rows:
                    count: pin-per-side
                    interval: pin-interval
            border:
                width: 6.5mm
                height: 6.5mm

#new LQFP48