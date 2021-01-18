#! requires PinArray


# 2.54 Pin header connectors
# -------------------------------------------

add-class class Conn_5pin_2_54_thd extends PinArray
    @rev_Conn_5pin_2_54_thd = 1
    (data, overrides) ->
        super data, overrides `based-on` do
            pad:
                dia: 2mm
                drill: 1mm
            cols:
                count: 5
                interval: 2.54mm
            rows:
                count: 1
            dir: 'x'

add-class class Conn_2pin_2_54_thd extends Conn_5pin_2_54_thd
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 2

add-class class Conn_3pin_2_54_thd extends Conn_5pin_2_54_thd
    @rev_Conn_3pin_2_54_thd = 1
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 3

add-class class Conn_4pin_2_54_thd extends Conn_5pin_2_54_thd
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 4

add-class class Conn_4pin_thd extends Conn_5pin_2_54_thd
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 4

add-class class Conn_6pin_2_54_thd extends Conn_5pin_2_54_thd
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 6

