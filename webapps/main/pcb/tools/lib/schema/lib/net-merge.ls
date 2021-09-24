
'''
# Arguments

* conn-tree   : Array of connected sub-nets, like:

    conn-tree =
        <[ a b x y z]>
        <[ a c ]>
        <[ c d ]>

* net         : (Optional) Array of strings of all or additional (unconnected) elements

# Returns Array of array of connected elements

# - TODO: https://stackoverflow.com/q/21900713/1952991

'''


require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail, unique-by, intersection, union
}


intersects = (a1, a2) -> not empty intersection a1, a2

export net-merge = (conn-tree, net) ->
    unless conn-tree
        throw new Error "Tree is missing"

    lookup = conn-tree
    _fuse = 0 # fuse for "while true"
    while true
        merged-tree = []
        mindex = []

        for i1, net1 of lookup when i1 not in mindex
            merged = net1
            #console.log "#{i1}: merged:", merged, "mindex:", mindex
            for i2, net2 of lookup when +i2 > +i1
                # combinations
                if net1 `intersects` net2
                    merged = union merged, net2
                    mindex.push i2
                    #console.log "++ [#{net1.join ','}] intersects with [#{net2.join ','}], mindex: ", mindex
            #console.log "examined #{i1}: pushing merged into tree:", merged
            merged-tree.push merged
        lookup = merged-tree
        if mindex.length is 0
            break
        if ++_fuse > 100
            debugger
            throw "Something is wrong with net-merge function!"
            break
    merged-tree = lookup

    # find out stray nodes
    if net
        stray-pads = net `difference` flatten merged-tree
        # append the additional pads to merged tree as 1-element-array
        merged-tree ++= [[..] for unique stray-pads]

    return merged-tree

# Tests
# ---------------------------------------------------------------------
require! 'dcs/lib/test-utils': {make-tests}

make-tests "net-merge", tests =
    "simple": ->
        net = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ d e ]>

        expect net-merge tree, net
        .to-equal x =
            <[ a b ]>
            <[ c ]>
            <[ d e ]>

    'missing tree': ->
        expect (-> net-merge null)
        .to-throw "Tree is missing"

    "net has only additional elements": ->
        net = <[ g h i ]>
        tree =
            <[ a b ]>
            <[ c d ]>
            <[ e f ]>
            <[ a c ]>
            <[ e d ]>

        expect net-merge tree, net
        .to-equal x =
            <[ a b c d e f ]>
            <[ g ]>
            <[ h ]>
            <[ i ]>

    "all networks are eventually connected": ->
        net = <[ a b c d e f ]>
        tree =
            <[ a b ]>
            <[ c d ]>
            <[ e f ]>
            <[ a c ]>
            <[ e d ]>

        expect net-merge tree, net
        .to-equal x =
            <[ a b c d e f ]>
            ...

    "simple 2": ->
        net = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ c d e ]>

        expect net-merge tree, net
        .to-equal x =
            <[ a b ]>
            <[ c d e ]>

    'indirectly connected': ->
        net = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ c d e a ]>

        expect net-merge tree, net
        .to-equal x =
            <[ a b c d e ]>
            ...

    'non-functional connection': ->
        net = <[ a b c d e ]>
        tree =
            <[ a ]>
            ...

        expect net-merge tree, net
        .to-equal x =
            <[ a ]>
            <[ b ]>
            <[ c ]>
            <[ d ]>
            <[ e ]>

    "large net": ->
        tree = [
            ["a","b"]
            ["c"],
            ["i","j","k","l","m","n"],
            ["p"],
            ["s"],
            ["u"],
            ["w"],
            ["z"],
            ["ad"],
            ["688"],
            ["i","j","k","l","m","n"],
        ]

        expect net-merge tree
        .to-equal x = 
                ["a","b"]
                ["c"],
                ["i","j","k","l","m","n"],
                ["p"],
                ["s"],
                ["u"],
                ["w"],
                ["z"],
                ["ad"],
                ["688"],
