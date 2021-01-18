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