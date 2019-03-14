
'''
# Arguments

* conn-tree   : Array of connected sub-nets, like:

    conn-tree =
        <[ a b x y z]>
        <[ a c ]>
        <[ c d ]>

* net         : (Optional) Array of all elements, like <[ a b c d ]>

# Returns

Object =
    merged: Array of array of connected elements
    stray: First elements (as a sample) of each array of "merged" tree if "merged" is disjointed (has more than one array).

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

    # There are 3 possibilities here:
    # 1. Reference net (and its pads)
    # 2. Stray nets (and their pads)
    # 3. Stray pads
    #
    # Procedure:
    # 1. If there are stray pads or stray net(s), sample a pad from ref.
    #    and put into unconnected too

    unconn = null
    # find out stray nodes
    if net
        unconn = [] # unconnected pad names
        stray-pads = net `difference` flatten merged-tree

        # TODO: BELOW IS DEPRECATED. THERE IS NO NEED FOR "stray" reference in the application,
        # use the elements whose length is 1 in the "merged" reference instead.
        has-stray-nets = merged-tree.length > 1
        if not empty stray-pads or has-stray-nets
            # we have unconnected pads, use `first ref` as entry point
            if first merged-tree
                unconn.push first that

        for stray-pads
            unconn.push ..

        # add stray nets' first pads as entry point
        for tail merged-tree or []
            if first ..
                unconn.push that
        ## END OF DEPRECATION 

        # append the additional pads to merged tree
        merged-tree ++= [[..] for stray-pads]

    {merged: merged-tree, stray: unconn}

# Tests
# ---------------------------------------------------------------------
require! 'dcs/lib/test-utils': {make-tests}

make-tests "net-merge", tests =
    1: ->
        net = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ d e ]>

        expect net-merge tree, net
        .to-equal do
            merged:
                <[ a b ]>
                <[ c ]>
                <[ d e ]>
            stray: <[ a c d ]>

    'missing tree': ->
        expect (-> net-merge null)
        .to-throw "Tree is missing"

    22: ->
        net = <[ a b c d e f ]>
        tree =
            <[ a b ]>
            <[ c d ]>
            <[ e f ]>
            <[ a c ]>
            <[ e d ]>

        expect net-merge tree, net
        .to-equal do
            merged:
                <[ a b c d e f ]>
                ...
            stray: []

    2: ->
        net = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ c d e ]>

        expect net-merge tree, net
        .to-equal do
            merged:
                <[ a b ]>
                <[ c d e ]>
            stray: <[ a c ]>

    'indirectly connected': ->
        net = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ c d e a ]>

        expect net-merge tree, net
        .to-equal do
            merged:
                <[ a b c d e ]>
                ...
            stray: []

    'non-functional connection': ->
        net = <[ a b c d e ]>
        tree =
            <[ a ]>
            ...

        expect net-merge tree, net
        .to-equal do
            merged:
                <[ a ]>
                <[ b ]>
                <[ c ]>
                <[ d ]>
                <[ e ]>
            stray: <[ a b c d e ]>

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
        .to-equal do
            merged:
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
            stray: null
