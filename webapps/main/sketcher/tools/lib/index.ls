require! './get-aecad': {get-aecad}
require! './get-class': {get-class, add-class}
require! './find-comp': {find-comp}
require! './component-base': {ComponentBase}
require! './container': {Container}
require! './footprint': {Footprint}
require! './pad': {Pad}
require! './trace': {Trace}

export get-class
export add-class
export find-comp
export get-aecad

# Component classes
export Container
export Footprint
export Pad
export Trace


for [Container, Footprint, Pad, Trace]
    add-class ..
