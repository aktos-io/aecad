#! requires PinArray
# From http://www.resistorguide.com/resistor-sizes-and-packages/
smd1206 =
    a: 1.6mm
    b: 0.9mm
    c: 2mm

{a, b, c} = smd1206

add-class class SMD1206 extends PinArray
    @rev_SMD1206 = 1
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'r_'
            pad:
                width: b
                height: a
            cols:
                count: 2
                interval: c + b
            border:
                width: c
                height: a

#new SMD1206

add-class class SMD1206_pol extends SMD1206
    # Polarized version of SMD1206
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'c_'
            labels:
                1: 'c'
                2: 'a'
            mark: yes

add-class class LED1206 extends SMD1206_pol

add-class class C1206 extends SMD1206_pol

add-class class DO214AC extends SMD1206_pol
    # https://www.vishay.com/docs/88746/ss12.pdf
    @rev_DO214AC = 2
    (data, overrides) ->
        super data, overrides `based-on` defaults =
            name: 'd_'
            pad:
                width: 1.52mm
                height: 1.68mm
            cols:
                count: 2
                interval: 5.28mm - 1.52mm

#new DO214AC


add-class class Sense1206 extends Footprint
    create: (data) ->
        #console.log "Creating from scratch PinArray"
        interval = c + b
        pad =
            width: b
            height: a

        new Pad pad <<< do
            pin: "1"
            label: "1"
            parent: this

        new Pad pad <<< do
            pin: "2"
            label: "2"
            parent: this
            position:
                x: interval

        trace-pad =
            width: 0.2mm
            height: 0.2mm

        new Pad do
            width: trace-pad.width
            height: trace-pad.height
            pin: "3"
            label: "sense1"
            parent: this
            position:
                x: b - 0.01
                y: a / 2 - trace-pad.height / 2

        new Pad do
            width: trace-pad.width
            height: trace-pad.height
            pin: "4"
            label: "sense2"
            parent: this
            position:
                x: 0.01 + interval - trace-pad.width
                y: a / 2 - trace-pad.height / 2

        @iface =
            "1": "1"
            "2": "2"
            "3": "sense1"
            "4": "sense2"

        if data.mirror
            # useful for female headers
            @mirror!

        @make-border do
            border:
                width: (c + 2 * b) + 0.1
                height: a + 0.1


#new Sense1206