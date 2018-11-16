require! 'prelude-ls': {empty, difference}

export combinations = (input, ffunc=(-> it)) ->
    comb = []
    for i in input.0
        :second for j in input.1
            continue if i is j
            for comb
                if empty difference [i, j].map(ffunc), ..map(ffunc)
                    continue second
            comb.push [i, j]
    comb

a = <[ a b c d ]>
out = combinations [a, a]
expected = [["a","b"],["a","c"],["a","d"],["b","c"],["b","d"],["c","d"]]
if JSON.stringify(out) isnt JSON.stringify(expected)
    throw "Problem in combinations: 1"

a =
    {src: 'a'}
    {src: 'b'}
    {src: 'c'}
    {src: 'd'}
out = combinations [a, a]
expected =
    [{src: 'a'},{src: "b"}]
    [{src: "a"},{src: "c"}]
    [{src: "a"},{src: "d"}]
    [{src: "b"},{src: "c"}]
    [{src: "b"},{src: "d"}]
    [{src: "c"},{src: "d"}]
if JSON.stringify(out) isnt JSON.stringify(expected)
    throw "Problem in combinations: 2"


'''
Usage:

    # create guide for specific source
    sch.guide-for \c1.vin

    # create all guides
    sch.guide-all!

    # get a schema (or "curr"ent schema) by SchemaManager
    sch2 = new SchemaManager! .curr

'''



export parse-name = (full-name, opts) ->
    unless opts => opts = {}
    link = no
    [...name, pin] = full-name.split '.'
    name = name.join '.'
    res = {name, pin}
    ext = [..name for (opts.external or [])]
    #console.log "externals: ", ext
    if name in ext
        res.link = yes
        res.name = full-name

    unless name
        # This is a cross reference
        res.name = full-name
        delete res.pin
        res.link = yes

    if opts.prefix
        res.raw = res.name
        res.name = "#{that}#{res.name}"
    return res

tests =
    1:
        full-name: "a.b.c.d"
        expected: {name: "a.b.c", pin: 'd'}
    2:
        full-name: "a"
        expected: {name: "a", link: yes}
    3:
        full-name: "a"
        opts: {prefix: 'hello.'}
        expected: {name: "hello.a", link: yes, raw: 'a'}
    4:
        full-name: "a.b"
        opts: {prefix: 'hello.'}
        expected: {name: "hello.a", pin: 'b', raw: 'a'}

for k, test of tests
    res = parse-name(test.full-name, test.opts)
    unless JSON.stringify(res) is JSON.stringify(test.expected)
        console.error "Expected: ", test.expected, "Got: ", res
        throw new Error "Test failed for 'parse-name': at test num: #{k}"
