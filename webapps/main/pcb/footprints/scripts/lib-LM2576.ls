#! requires TO263
add-class class LM2576 extends TO263
    # http://www.ti.com/lit/ds/symlink/lm2576.pdf
    @rev_LM2576 = 2
    (data, overrides) ->
        super data, overrides `based-on` do
            labels:
                # Pin_id: Label
                1: \vin
                2: \out
                3: \gnd
                4: \fb
                5: \onoff
                6: \gnd
            allow-duplicate-labels: yes

#a = new LM2576
#a.get {pin: 'vin'}