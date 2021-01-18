#! requires DoublePinArray

add-class class HTSSOP_20 extends DoublePinArray
    # Reference: https://www.analog.com/media/en/package-pcb-resources/package/pkg_pdf/ltc-legacy-tssop/TSSOP_38_05-08-1865.pdf
    @rev_HTSSOP_20 = 2

    (data, overrides) ->
        pin-count = overrides?pin-count or 20

        pad = data?.pad or pad =
            width: 1.05mm
            height: 0.315mm

        pad-interval = 0.5mm
        super data, overrides `based-on` do
            name: 'r_'
            dir: '-x'
            distance: 7.2 - pad.width
            left:
                pad: pad
                rows:
                    count: pin-count/2
                    interval: pad-interval
            right:
                start: pin-count/2 + 1
                pad: pad
                dir: '-y'
                rows:
                    count: pin-count/2
                    interval: pad-interval
            border:
                width: 4.40mm - 0.3mm
                height: 0.5mm + (pin-count / 2 * pad-interval)


#new HTSSOP_20

add-class class HTSSOP_38 extends HTSSOP_20
    (data, overrides) ->
        super data, overrides `based-on` do
            pin-count: 38


#new HTSSOP_38