
'''
# Arguments

* conn-tree   : Array of connected sub-nets, like:

    conn-tree =
        <[ a b x y z]>
        <[ a c ]>
        <[ c d ]>

* all-elems         : (Optional) Array of strings of all or additional (unconnected) elements

# Returns Array of array of connected elements

# - TODO: https://stackoverflow.com/q/21900713/1952991

'''


require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail, unique-by, intersection, union
}


intersects = (a1, a2) -> not empty intersection a1, a2

export net-merge = (conn-tree, all-elems) ->
    unless conn-tree
        throw new Error "Tree is missing"

    lookup = conn-tree
    _fuse = 0 # fuse for "while true"
    while true
        merged-tree = []
        mindex = []

        for i1, all-elems1 of lookup when i1 not in mindex
            merged = all-elems1
            #console.log "#{i1}: merged:", merged, "mindex:", mindex
            for i2, all-elems2 of lookup when +i2 > +i1
                # combinations
                if all-elems1 `intersects` all-elems2
                    merged = union merged, all-elems2
                    mindex.push i2
                    #console.log "++ [#{all-elems1.join ','}] intersects with [#{all-elems2.join ','}], mindex: ", mindex
            #console.log "examined #{i1}: pushing merged into tree:", merged
            merged-tree.push unique merged
        lookup = merged-tree
        if mindex.length is 0
            break
        if ++_fuse > 100
            debugger
            throw "Something is wrong with net-merge function!"
            break
    merged-tree = lookup

    # find out stray nodes
    if all-elems
        stray-pads = all-elems `difference` flatten merged-tree
        # append the additional pads to merged tree as 1-element-array
        merged-tree ++= [[..] for unique stray-pads]

    return merged-tree

# Tests
# ---------------------------------------------------------------------
require! 'dcs/lib/test-utils': {make-tests}

make-tests "net-merge", tests =
    "simple": ->
        all-elems = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ d e ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b ]>
            <[ c ]>
            <[ d e ]>

    "duplicate item": ->
        all-elems = <[ a a b c d e ]>
        tree =
            <[ a a b ]>
            <[ c ]>
            <[ d e ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b ]>
            <[ c ]>
            <[ d e ]>

    "many duplicates": ->
        all-elems = <[ a a b c d e e e e f ]>
        tree =
            <[ a a b ]>
            <[ c ]>
            <[ d e ]>
            <[ d e e]>
            <[ b a b b b b b c ]>
            <[ c ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b c ]>
            <[ d e ]>
            <[ f ]>

    'missing tree': ->
        expect (-> net-merge null)
        .to-throw "Tree is missing"

    "all-elems has only additional elements": ->
        all-elems = <[ g h i ]>
        tree =
            <[ a b ]>
            <[ c d ]>
            <[ e f ]>
            <[ a c ]>
            <[ e d ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b c d e f ]>
            <[ g ]>
            <[ h ]>
            <[ i ]>

    "all all-elemsworks are eventually connected": ->
        all-elems = <[ a b c d e f ]>
        tree =
            <[ a b ]>
            <[ c d ]>
            <[ e f ]>
            <[ a c ]>
            <[ e d ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b c d e f ]>
            ...

    "simple 2": ->
        all-elems = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ c d e ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b ]>
            <[ c d e ]>

    'indirectly connected': ->
        all-elems = <[ a b c d e ]>
        tree =
            <[ a b ]>
            <[ c ]>
            <[ c d e a ]>

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a b c d e ]>
            ...

    'non-functional connection': ->
        all-elems = <[ a b c d e ]>
        tree =
            <[ a ]>
            ...

        expect net-merge tree, all-elems
        .to-equal x =
            <[ a ]>
            <[ b ]>
            <[ c ]>
            <[ d ]>
            <[ e ]>

    "large all-elems": ->
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
