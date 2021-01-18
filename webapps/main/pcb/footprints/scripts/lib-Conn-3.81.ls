#! requires PinArray

# 3.81 connectors
# -------------------------------------------
add-class class Conn_2pin_3_81_thd extends PinArray
    @rev_Conn_2pin_3_81_thd = 2
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

add-class class Conn_4pin_3_81_thd extends Conn_2pin_3_81_thd
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 4

add-class class Conn_2pin_thd extends Conn_2pin_3_81_thd
