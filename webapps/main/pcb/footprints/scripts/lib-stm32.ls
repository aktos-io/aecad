#! requires TSSOP_20
#! requires LQFP48

add-class class STM32F103C8 extends LQFP48
    (data) ->
        super data, defaults =
            labels:
                1: \VBAT
                2: \PC13 # TAMPER - RTC
                3: \PC14 # OSC32_IN
                4: \PC15 # OSC32_OUT
                5: \PD0 # OSC_IN
                6: \PD1 # OSC_OUT
                7: \NRST
                8: \VSSA
                9: \VDDA
                10: \PA0 # WKUP
                11: \PA1
                12: \PA2

                13: \PA3
                14: \PA4
                15: \PA5
                16: \PA6
                17: \PA7
                18: \PB0
                19: \PB1
                20: \PB2
                21: \PB10
                22: \PB11
                23: \VSS_1
                24: \VDD_1

                25: \PB12
                26: \PB13
                27: \PB14
                28: \PB15
                29: \PA8
                30: \PA9 # USART1_TX
                31: \PA10 # USART1_RX
                32: \PA11
                33: \PA12
                34: \SWDIO # PA13
                35: \VSS_2
                36: \VDD_2

                37: \SWCLK # PA14
                38: \PA15
                39: \PB3
                40: \PB4
                41: \PB5
                42: \PB6
                43: \PB7
                44: \Boot0
                45: \PB8
                46: \PB9
                47: \VSS_3
                48: \VDD_3


#new STM32F103C8

add-class class STM32F030_20 extends TSSOP_20
    (data) ->
        super data, defaults =
            labels:
                1: \Boot0
                2: \PF0 # OSC_IN
                3: \PF1 # OSC_OUT
                4: \NRST
                5: \VDDA
                6: \PA0 # WKUP
                7: \PA1
                8: \PA2
                9: \PA3
                10: \PA4

                11: \PA5
                12: \PA6
                13: \PA7
                14: \PB1
                15: \VSS
                16: \VDD
                17: \PA9
                18: \PA10
                19: \PA13 # SWDIO
                20: \PA14 # SWCLK


#new STM32F030_20