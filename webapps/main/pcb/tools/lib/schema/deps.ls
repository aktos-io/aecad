# lib imports
require! '../find-comp': {find-comp}
require! '../../../kernel': {PaperDraw}
require! '../text2arr': {text2arr}
require! '../get-class': {get-class}
require! '../get-aecad': {get-aecad}
require! '../lib': {get-rev}

parse-params = (input) -> 
    params = input
    if typeof! input is \String
        # Items separated by pipe characters in key:value format 
        # unless a regex is provided for parsing 
        params = {}
        for input.split '|' 
            [k, v] = ..split ':'
            params[k] = v or null
    return params

export {
    find-comp, PaperDraw, text2arr, get-class, get-aecad
    get-rev
    parse-params
}

