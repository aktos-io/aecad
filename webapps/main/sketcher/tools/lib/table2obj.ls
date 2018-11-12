
# Converts ascii (markdown) table to Object with key is format.key
export table2obj = (format, table) ->
    rows = table.split '\n'
    is-header = true
    json = []
    for i from 0 to rows.length - 1
        row = rows[i]

        # strip first and last "|" character
        while row.char-at(0) is '|'
            row = row.substr 1
        while row.char-at(row.length - 1) is '|'
            row = row.substr 0, row.length - 1

        # skip first line if it's a splitter
        if i is 0 and row.0 is '+'
            continue

        # detect header entry and exits
        if row.0 is '+'
            is-header = not is-header
            continue

        if is-header
            header = row.split '|' .map (.trim!)
        else
            is-symmetric = row.split('||').lentgh is 2
            [first, second] = row.split '||' .map (.split '|' .map (.trim!))
            second = second.reverse!
            left = {}
            right = {}
            for col to first.length
                left[header[col]] = first[col]?.replace /\s/, ''
                right[header[col]] = second[col]?.replace /\s/, ''
            json.push left
            json.push right

    res = {}
    for row in json
        res[row[format.key]] = if format.value => row[format.value] else row
    return res


/* Usage:
#  table2obj {key: 'Physical', value: 'BCM'}, markdown-table
#  => returns {"Physical": "BCM"} obj
#
#  table2obj {key: 'Physical'}, markdown-table
#  => returns {"Physical": {row}} obj
#----------------------------------------------------------------


table = table2obj {key: 'Physical', value: 'BCM'}, '''
+-----+-----+---------+------+---+---Pi 3---+---+------+---------+-----+-----+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
| 3v3 | 3v3 |    3.3v |      |   |  1 || 2  |   |      | 5v      | 5v  | 5v  |
|   2 |   8 |   SDA.1 | ALT0 | 1 |  3 || 4  |   |      | 5V      | 5v  | 5v  |
|   3 |   9 |   SCL.1 | ALT0 | 1 |  5 || 6  |   |      | 0v      | gnd | gnd |
|   4 |   7 | GPIO. 7 |   IN | 1 |  7 || 8  | 1 | ALT5 | TxD     | 15  | 14  |
| gnd | gnd |      0v |      |   |  9 || 10 | 1 | ALT5 | RxD     | 16  | 15  |
|  17 |   0 | GPIO. 0 |   IN | 0 | 11 || 12 | 0 | IN   | GPIO. 1 | 1   | 18  |
|  27 |   2 | GPIO. 2 |   IN | 0 | 13 || 14 |   |      | 0v      | gnd | gnd |
|  22 |   3 | GPIO. 3 |   IN | 0 | 15 || 16 | 0 | IN   | GPIO. 4 | 4   | 23  |
| 3v3 | 3v3 |    3.3v |      |   | 17 || 18 | 0 | IN   | GPIO. 5 | 5   | 24  |
|  10 |  12 |    MOSI | ALT0 | 0 | 19 || 20 |   |      | 0v      | gnd | gnd |
|   9 |  13 |    MISO | ALT0 | 0 | 21 || 22 | 0 | IN   | GPIO. 6 | 6   | 25  |
|  11 |  14 |    SCLK | ALT0 | 0 | 23 || 24 | 1 | OUT  | CE0     | 10  | 8   |
| gnd | gnd |      0v |      |   | 25 || 26 | 1 | OUT  | CE1     | 11  | 7   |
|   0 |  30 |   SDA.0 |   IN | 1 | 27 || 28 | 1 | IN   | SCL.0   | 31  | 1   |
|   5 |  21 | GPIO.21 |   IN | 1 | 29 || 30 |   |      | 0v      | gnd | gnd |
|   6 |  22 | GPIO.22 |   IN | 1 | 31 || 32 | 0 | IN   | GPIO.26 | 26  | 12  |
|  13 |  23 | GPIO.23 |   IN | 0 | 33 || 34 |   |      | 0v      | gnd | gnd |
|  19 |  24 | GPIO.24 |   IN | 0 | 35 || 36 | 0 | IN   | GPIO.27 | 27  | 16  |
|  26 |  25 | GPIO.25 |   IN | 0 | 37 || 38 | 0 | IN   | GPIO.28 | 28  | 20  |
| gnd | gnd |      0v |      |   | 39 || 40 | 0 | IN   | GPIO.29 | 29  | 21  |
+-----+-----+---------+------+---+----++----+---+------+---------+-----+-----+
| BCM | wPi |   Name  | Mode | V | Physical | V | Mode | Name    | wPi | BCM |
+-----+-----+---------+------+---+---Pi 3---+---+------+---------+-----+-----+
'''

console.log table

*/
