# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------

#! requires PinArray
add-class class Inductor extends PinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'L_'
            pad:
                width: 4mm
                height: 4.5mm
            cols:
                count: 2
                interval: 8mm
            border:
                width: 10.7mm
                height: 10.2mm

add-class class Inductor_thd extends Inductor
    (data, overrides) ->
        super data, overrides `based-on` do
            pad:
                drill: 0.7mm

#new Inductor_thd
#new Inductor