require! 'components'
require! 'aea/default-helpers'
require! './terminal-block'

new Ractive do
    el: \body
    template: RACTIVE_PREPARSE('app.pug')
