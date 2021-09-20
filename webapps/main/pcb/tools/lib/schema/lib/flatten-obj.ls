require! 'dcs/lib/test-utils': {make-tests}

export flatten-obj = (obj) -> 
    recheck = false 
    for k, v of obj 
        if typeof! v is \Object 
            # prefix the key with outer key 
            for _k, _v of v 
                new-key = "#{k}.#{_k}"
                if new-key of obj
                    throw new Error "Duplicate key found while flattening: \"#{new-key}\""
                obj[new-key] = _v 
                if typeof! _v is \Object 
                    recheck = true 
            delete obj[k]

    unless recheck 
        return obj 

    return flatten-obj obj 


make-tests "flatten-obj", do
    1: -> 
        obj = 
            1: "foo"
            2: 
                3: "bar"
                4: "baz"

        expected = 
            1: "foo"
            "2.3": "bar"
            "2.4": "baz"

        expect flatten-obj obj 
        .to-equal expected 

    2: -> 
        obj = 
            1: "foo"
            "2": 
                3: "bar"
                4:
                    "qux": 1
                    "baz": 2

        expected = 
            1: "foo"
            "2.3": "bar"
            "2.4.qux": 1
            "2.4.baz": 2

        expect flatten-obj obj 
        .to-equal expected 

    "deeper": -> 
        obj = 
            1: "foo"
            "2": 
                3: "bar"
                4:
                    "qux": 1
                    "baz": 
                        1: "bat"
                        2: 
                            3: 
                                4: 
                                    "foo"

        expected = 
            1: "foo"
            "2.3": "bar"
            "2.4.qux": 1
            "2.4.baz.1": "bat"
            "2.4.baz.2.3.4": "foo"

        expect flatten-obj obj 
        .to-equal expected 

    "collision": -> 
        obj = 
            1: "foo"
            "2": 
                3: "bar"
                4:
                    "qux": 1
                    "baz": 
                        1: "bat"
                        2: 
                            3: 
                                4: 
                                    "foo"
            "2.4.baz.2.3.4": "x"

        expected = 
            1: "foo"
            "2.3": "bar"
            "2.4.qux": 1
            "2.4.baz.1": "bat"
            "2.4.baz.2.3.4": "foo"

        expect (-> flatten-obj obj) 
        .to-throw "Duplicate key found while flattening: \"2.4.baz.2.3.4\"" 
