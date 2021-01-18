#! requires PinArray

add-class class Bolt_3mm extends PinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'conn_'
            pad:
                dia: 6.2mm
                drill: 3mm
