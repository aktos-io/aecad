/*
Accumulates all pedigree revisions (@rev_* values) to generate
an overall revision value.

This way, if a sub-class revision is bumped, all upper classes' revisions
are bumped too.
*/

export get-rev = (cls) ->
    rev = 0
    for to 100
        if cls["rev_#{cls.name}"]
            rev += +that
        if cls.superclass
            cls = that
        else
            break
    rev

require! 'dcs/lib/test-utils': {make-tests}

make-tests 'get-rev', do
    'simple': ->
        # Usage of `get-rev`
        class C
            @rev_C = "4"

        class B extends C
            #@rev_B = "3"

        class A extends B
            @rev_A = "2"

        expect get-rev(A)
        .to-equal 6
