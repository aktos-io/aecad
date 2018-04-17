require! \components

new Ractive do
    el: \body
    template: RACTIVE_PREPARSE('app.html')
    data:
        name: "world"
