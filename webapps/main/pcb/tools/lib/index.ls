require! './get-aecad': {get-aecad, get-parent-aecad}
require! './get-class': {get-class, add-class}
require! './find-comp': {find-comp}
require! './component-base': {ComponentBase}
require! './table2obj': {table2obj}
require! './schema': {Schema, SchemaManager}
require! './text2arr': {text2arr}

utils = {
    get-class, add-class, 
    provides: add-class # alias 
    get-aecad, get-parent-aecad
    find-comp
    ComponentBase
    table2obj
    Schema, SchemaManager
    text2arr
}

# Component classes
require! './container': {Container}
require! './footprint': {Footprint}
require! './pad': {Pad}
require! './trace': {Trace}
require! './edge': {Edge}

component-classes = {
    Container, Footprint, Pad, Trace, Edge
}

for n, cls of component-classes
    add-class cls

module.exports = utils <<< component-classes
