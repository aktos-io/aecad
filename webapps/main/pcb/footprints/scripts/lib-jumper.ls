#! requires PinArray


# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------
add-class class TestBoundary extends PinArray
    (data, overrides) ->
        super data, overrides `based-on` do
            pad:
                width: 0.2mm
                height: 0.5mm
            cols:
                count: 2
                interval: 0.3mm
            rows:
                count: 1
            dir: 'x'
            labels:
                1: 1
                2: 1
            allow-duplicate-labels: yes
            is-virtual: yes # do not include into BOM list

add-class class TestBoundary1206 extends TestBoundary
    @rev_TestBoundary1206 = 2
    (data, overrides) ->
        a = 1.6mm
        b = (a - 0.2mm) / 2

        super data, overrides `based-on` do
            pad:
                width: b
                height: a
            cols:
                interval: a - b

#new TestBoundary1206