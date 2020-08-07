require! 'prelude-ls': {keys, map, maximum}

# Generates next available numerical id in an object
export next-id = (obj) ->
    curr = obj
        |> keys
        |> map parse-int
        |> maximum
    return (curr or 0) + 1

tests =
    1:
        obj:
            1: 'foo'
            3: 'bar'
        expected: 4

    2:
        obj: null
        expected: 1

    3:
        obj: {}
        expected: 1

    4:
        obj:
            1: 'foo'
            'hello': 'world'
            4: 'bar'
        expected: 5

    5:
        obj:
            1: 'foo'
            'hello': 'world'
        expected: 2
    6:
        obj:
            1: 'foo'
            "2": 'world'
        expected: 3

for k, test of tests
    res = next-id test.obj
    unless res is test.expected
        console.error "Expected: ", test.expected, "Got: ", res
        throw new Error "Test failed for 'next-id': at test num: #{k}"
