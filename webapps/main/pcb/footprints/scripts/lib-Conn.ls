#! requires PinArray
add-class class Conn_2pin_thd extends PinArray
    @rev_Conn_2pin_thd = 2
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'conn_'
            pad:
                dia: 3.1mm
                drill: 1.2mm
            cols:
                count: 2
                interval: 3.81mm
            rows:
                count: 1
            dir: 'x'


add-class class Conn_1pin_thd extends PinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'conn_'
            pad:
                dia: 3.1mm
                drill: 1mm
            cols:
                count: 1
            rows:
                count: 1
            dir: 'x'


add-class class Bolt extends PinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'conn_'
            pad:
                dia: 6.2mm
                drill: 3mm

#new Conn_2pin_thd
#new Conn_1pin_thd
