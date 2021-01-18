#! requires PinArray
# --------------------------------------------------
# all lib* scripts will be included automatically.
#
# This script will also be treated as a library file.
# --------------------------------------------------
table = '''
+------+-----+---------+------+---+---Pi 3---+---+------+---------+-----+------+
| BCM  | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM  |
+------+-----+---------+------+---+----++----+---+------+---------+-----+------+
| 3v3  | 3v3 |    3.3v |      |   |  1 || 2  |   |      | 5v      | 5v  | 5v   |
|   2  |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5V      | 5v  | 5v   |
|   3  |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | 0v      | gnd | gnd4 |
|   4  |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 1 | ALT5 | TxD     | 15  | 14   |
| gnd1 | gnd |      0v |      |   |  9 || 10 | 1 | ALT5 | RxD     | 16  | 15   |
|  17  |   0 | GPIO. 0 |   IN | 0 | 11 || 12 | 0 | IN   | GPIO. 1 | 1   | 18   |
|  27  |   2 | GPIO. 2 |   IN | 0 | 13 || 14 |   |      | 0v      | gnd | gnd5 |
|  22  |   3 | GPIO. 3 |   IN | 0 | 15 || 16 | 0 | IN   | GPIO. 4 | 4   | 23   |
| 3v3  | 3v3 |    3.3v |      |   | 17 || 18 | 0 | IN   | GPIO. 5 | 5   | 24   |
|  10  |  12 |    MOSI | ALT0 | 0 | 19 || 20 |   |      | 0v      | gnd | gnd6 |
|   9  |  13 |    MISO | ALT0 | 0 | 21 || 22 | 0 | IN   | GPIO. 6 | 6   | 25   |
|  11  |  14 |    SCLK | ALT0 | 0 | 23 || 24 | 1 | OUT  | CE0     | 10  | 8    |
| gnd2 | gnd |      0v |      |   | 25 || 26 | 1 | OUT  | CE1     | 11  | 7    |
|   0  |  30 |   SDA.0 |   IN | 1 | 27 || 28 | 1 | IN   | SCL.0   | 31  | 1    |
|   5  |  21 | GPIO.21 |   IN | 1 | 29 || 30 |   |      | 0v      | gnd | gnd7 |
|   6  |  22 | GPIO.22 |   IN | 1 | 31 || 32 | 0 | IN   | GPIO.26 | 26  | 12   |
|  13  |  23 | GPIO.23 |   IN | 0 | 33 || 34 |   |      | 0v      | gnd | gnd8 |
|  19  |  24 | GPIO.24 |   IN | 0 | 35 || 36 | 0 | IN   | GPIO.27 | 27  | 16   |
|  26  |  25 | GPIO.25 |   IN | 0 | 37 || 38 | 0 | IN   | GPIO.28 | 28  | 20   |
| gnd3 | gnd |      0v |      |   | 39 || 40 | 0 | IN   | GPIO.29 | 29  | 21   |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-------+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+---Pi 3---+---+------+---------+-----+-----+
'''

add-class class RpiHeader extends PinArray
    @rev_RpiHeader = 1
    (data) ->
        super data, defaults =
            name: 'rpi_'
            pad:
                width: 3.1mm
                height: 1.5mm
            cols:
                count: 2
                interval: 5.5mm
            rows:
                count: 20
                interval: 2.54mm
            dir: 'x'
            labels: table2obj {key: 'Physical', value: 'BCM'}, table
            mirror: yes
            disallow-pin-numbers: yes
            allow-duplicate-labels: yes
