#! requires DoublePinArray

add-class class TSSOP_20 extends DoublePinArray
      (data, overrides) ->
          pin-count = overrides?pin-count or 20

          pad = data?.pad or pad =
              width: 1.35mm
              height: 0.40mm

          super data, overrides `based-on` do
              name: 'r_'
              dir: '-x'
              distance: 7.10 - 1.35
              left:
                  pad: pad
                  rows:
                      count: pin-count/2
                      interval: 0.65mm
              right:
                  start: pin-count/2 + 1
                  pad: pad
                  dir: '-y'
                  rows:
                      count: pin-count/2
                      interval: 0.65mm
              border:
                  width: 4.40mm - 0.3
                  height: 7mm * (pin-count / 20)

#new TSSOP_20

add-class class TSSOP_38 extends TSSOP_20
    (data, overrides) ->
        super data, overrides `based-on` do
            pin-count: 38


#new TSSOP_38