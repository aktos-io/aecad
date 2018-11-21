
'''
# Arguments

net         : array of all elements, like <[ a b c d ]>
conn-tree   : array of connected sub-nets, like:

    conn-tree =
        <[ a b x y z]>
        <[ a c ]>
        <[ c d ]>

# Returns

Object =
    merged: merged conn-tree
    stray: stray (unconnected) elements

# - TODO: https://stackoverflow.com/q/21900713/1952991

'''

require! 'prelude-ls': {
    find, empty, unique, difference, max, keys, flatten, filter, values
    first, tail, unique-by, intersection, union
}


export net-merge = (conn-tree, net) ->
    unless conn-tree
        throw new Error "Tree is missing"
    # if mutual pads can be found between two conn-tree, create a new branch with them
    merged-tree = [] # merged conn-tree (mark them in order not to include twice)
    _mindex = [] # merged branch indexes
    for i1, branch1 of conn-tree when i1 not in _mindex
        merged = branch1
        for i2, branch2 of conn-tree when i2 > i1 and i2 not in _mindex
            # combinations
            unless empty intersection branch1, branch2
                merged = union merged, branch2
                _mindex.push i2
        merged-tree.push merged

    # There are 3 possibilities here:
    # 1. Reference net (and its pads)
    # 2. Stray nets (and their pads)
    # 3. Stray pads
    #
    # Procedure:
    # 1. If there are stray pads or stray net(s), sample a pad from ref.
    #    and put into unconnected too

    unconn = [] # unconnected pad names
    stray-pads = net `difference` flatten merged-tree
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
