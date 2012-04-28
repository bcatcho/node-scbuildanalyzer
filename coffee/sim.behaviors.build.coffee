root = exports ? this

SCSim = root.SCSim ? {}; root.SCSim = SCSim
_ = root._ #require underscore


class SCSim.WarpInBuilder extends SCSim.Behavior
  constructor: ->

  @defaultState
    messages:
      build: (name) ->
        #nop
