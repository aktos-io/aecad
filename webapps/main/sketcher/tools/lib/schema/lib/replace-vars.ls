math = require 'mathjs'

export replace-vars = (src-data, target-obj) -> 
    res = {}
    for k, v of target-obj
        expr-container-regex = /{{(.+)}}/
        expr-container-match = expr-container-regex.exec k
        if expr-container-match
            # We found an expression. Evaluate it using src-data 
            expr = expr-container-match[1]
            #console.log "Found expression: ", expr, "src-data: ", src-data
            for var-name, var-value of src-data
                    variable-regex = new RegExp "\\b(" + var-name + ")\\b"
                    if variable-regex.exec expr
                        expr1 = expr.replace variable-regex, var-value
                        #console.log "expression found: ", expr, "replaced with:", expr1, "value was:", var-value
                        expr = expr1
                        try
                            expr = math.eval(expr)
            k = k.replace expr-container-regex, expr

        if typeof! v is \Object 
            v = replace-vars src-data, v
        res[k] = v 
    return res 


# Tests
# ---------------------------------------------------------------------
require! 'dcs/lib/test-utils': {make-tests}

make-tests "replace-vars", tests =
    "simple": ->
        parent = 
            M: "hello"

        target = 
            "{{M}}ohm": "a b c"

        expect replace-vars parent, target 
        .to-equal x = 
            "helloohm": "a b c"

    "expression": ->
        parent = 
            M: "2ohm"

        target = 
            "{{M * 2}}": "a b c"

        expect replace-vars parent, target 
        .to-equal x = 
            "4 ohm": "a b c"

    "no expression": ->
        parent = 
            M: "2ohm"

        target = 
            "hello": "a b c"

        expect replace-vars parent, target 
        .to-equal x = 
            "hello": "a b c"

    "nested": ->
        parent = 
            M: "hello"
            C: "there"

        target = 
            "{{M}}_y": 
                "{{C}}ohm": "a b c"


        expect replace-vars parent, target 
        .to-equal x = 
            "hello_y": 
                "thereohm": "a b c"
