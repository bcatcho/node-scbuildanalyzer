class SCSim.Hud
    @productionPotential = {} # how much could we do next

class SCSim.Smarts
  constructor: ->
    @strategies = {}
    @path = {} # a linked list of your build order
    # OR:
    @goals = {} # maybe a list of goals that you will need to meet

  decide: (hud) ->
    # for things in hud, apply strats, decide and return oommands
  
  applyStrategy: (inputName, methodThatDecidesWhatToDo) ->
    # define strategies to decide outcomes on certain input/alerts/etc


''' trainable behavior and blocking state '''

class Trainable extends Behavior
  # can we make it so that things are trainable?
  # by adding a behavior?
  # 
  # How does this behavior's update loop block others?
  # perhaps actors have a "blocking state" member that
  # gets all the updates when set

class Actor
  @blockingBehavior = undefined

  update: ->
    if @blockingBehavior isnt undefined
      @blockingBehavior()
    else
      loopdedoop()
