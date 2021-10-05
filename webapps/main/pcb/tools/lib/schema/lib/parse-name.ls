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

require! 'dcs/lib/test-utils': {make-tests}

make-tests "net-merge", do
    1: -> 
        expect parse-name "test.circuit-1.c1.PA15"
        .to-equal {name: "test.circuit-1.c1", pin: 'PA15'}
    2: -> 
        # "link" is 
        expect parse-name "a"
        .to-equal {name: "a", link: yes}
    3: -> 
        expect parse-name "a", {prefix: 'hello.'}
        .to-equal {name: "hello.a", link: yes, raw: 'a'}
    4: -> 

        expect parse-name "a.b", {prefix: 'hello.'}
        .to-equal {name: "hello.a", pin: 'b', raw: 'a'}
