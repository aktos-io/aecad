#! requires HTSSOP_38

add-class class DRV8711 extends HTSSOP_38
    (data) ->
        super data, defaults =
            labels:
                1: \CP1
                2: \CP2
                3: \VCP
                4: \VM
                5: \GND1
                6: \V5
                7: \VINT
                8: \SLEEPn
                9: \RESET
                10: \STEP_AIN1
                11: \DIR_AIN2
                12: \BIN1
                13: \BIN2
                14: \SCLK
                15: \SDATI
                16: \SCS
                17: \SDATO
                18: \FAULTn
                19: \STALLn_BEMFVn

                20: \BEMF
                21: \BOUT2
                22: \B2HS
                23: \B2LS
                24: \BISENN
                25: \BISENP
                26: \B1LS
                27: \B1HS
                28: \BOUT1
                29: \GND3
                30: \AOUT2
                31: \A2HS
                32: \A2LS
                33: \AISENN
                34: \AISENP
                35: \A1LS
                36: \A1HS
                37: \AOUT1
                38: \GND2

#new DRV8711