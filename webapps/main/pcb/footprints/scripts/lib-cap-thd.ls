#! requires PinArray
add-class class CAP_thd extends PinArray
    @rev_CAP_thd = 2
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'c_'
            pad:
                dia: 1.5mm
                drill: 0.6mm
            cols:
                count: 2
                interval: 4mm
            rows:
                count: 1
            labels:
                1: 'c'
                2: 'a'
            border:
                dia: 8mm


add-class class Buzzer extends CAP_thd
    (data, overrides) ->
        super data, overrides `based-on` do
            pad:
                drill: 0.7mm
            cols:
                interval: 7.70mm
            border:
                dia: 12mm

#new CAP_thd
#new Buzzer

