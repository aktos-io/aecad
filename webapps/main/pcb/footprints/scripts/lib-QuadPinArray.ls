#! requires PinArray

# See LQFP48 for example
add-class class QuadPinArray extends Footprint
    create: (data) ->
        overwrites =
            parent: this
            labels: data.labels

        left = new PinArray data.left <<< overwrites
        right = new PinArray data.right <<< overwrites
        top = new PinArray data.top <<< overwrites <<< {rotation: 90}
        bottom = new PinArray data.bottom <<< overwrites <<< {rotation: 90}

        iface = {}
        for num, label of left.iface
            iface[num] = label
        for num, label of right.iface
            iface[num] = label
        for num, label of top.iface
            iface[num] = label
        for num, label of bottom.iface
            iface[num] = label
        @iface = iface

        right.position = left.position.add [data.distance |> mm2px, 0]
        top.position = right.position.add left.position .divide 2 .subtract [0, (data.distance) / 2 |> mm2px]
        bottom.position = top.position.add [0, data.distance |> mm2px]
        @make-border data


