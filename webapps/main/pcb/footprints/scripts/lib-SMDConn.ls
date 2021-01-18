#! requires PinArray

add-class class SMDConn_3pin extends PinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            pad:
                width: 0.9
                height: 3.2
            cols:
                count: 3
                interval: 2.54mm
            border:
                width: 7mm
                height: 3.8mm

add-class class SMDConn_4pin extends SMDConn_3pin
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 4

add-class class SMDConn_5pin extends SMDConn_3pin
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 5

add-class class SMDConn_2pin extends SMDConn_3pin
    (data, overrides) ->
        super data, overrides `based-on` do
            cols:
                count: 2
