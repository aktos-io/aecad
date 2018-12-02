export class ComponentManager
    @instance = null
    ->
        # Make this class Singleton
        # ------------------------------
        return @@instance if @@instance
        @@instance = this
        # ------------------------------
        @cid = 1

    register: (component) ->
        # assign unique id only
        component.cid = @cid++  # component-id
