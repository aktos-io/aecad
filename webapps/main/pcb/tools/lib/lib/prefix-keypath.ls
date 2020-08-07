export prefix-keypath = (prefix, keypath) ->
    _keypath = (keypath or '').split '.'
    _prefix = (prefix or '').split '.'
    (_prefix ++ _keypath).filter((Boolean)).join('.')

tests =
    1:
        prefix: null
        keypath: "a.b.c.d"
        expected: "a.b.c.d"
    2:
        prefix: '.'
        keypath: "a.b.c.d"
        expected: "a.b.c.d"
    3:
        prefix: '..'
        keypath: "a.b.c.d"
        expected: "a.b.c.d"
    4:
        prefix: 'hello'
        keypath: "a"
        expected: "hello.a"
    5:
        prefix: 'hello'
        keypath: null
        expected: "hello"

for k, test of tests
    res = prefix-keypath(test.prefix, test.keypath)
    unless JSON.stringify(res) is JSON.stringify(test.expected)
        console.error "Expected: ", test.expected, "Got: ", res
        throw new Error "Test failed for 'parse-name': at test num: #{k}"
