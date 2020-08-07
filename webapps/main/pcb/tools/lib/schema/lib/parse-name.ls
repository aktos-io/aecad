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
