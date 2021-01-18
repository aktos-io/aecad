# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------

#! requires PinArray
add-class class Inductor extends PinArray
    @rev_Inductor = 2
    (data, overrides) ->
        super data, overrides `based-on` do
            name: 'L_'
            pad:
                height: 7.5mm
                width: 3mm
            cols:
                count: 2
                interval: 6mm
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