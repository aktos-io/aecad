#! requires PinArray

add-class class DoublePinArray extends Footprint
    create: (data) ->
        overwrites =
            parent: this
            labels: data.labels

        left = new PinArray data.left <<< overwrites
        right = new PinArray data.right <<< overwrites

        iface = {}
        for num, label of left.iface
            iface[num] = label
        for num, label of right.iface
            iface[num] = label
        @iface = iface

        right.position = left.position.add [data.distance |> mm2px, 0]
        @make-border data