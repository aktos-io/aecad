#! requires SOT223
add-class class LM1117 extends SOT223
    @rev_LM1117 = 1
    (data, overrides) ->
        super data, overrides `based-on` do
            labels:
                # Pin_id: Label
                1: 'gnd'
                2: 'vout'
                3: 'vin'
                4: 'vout'
            allow-duplicate-labels: yes