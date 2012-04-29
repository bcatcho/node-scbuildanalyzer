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
  ###
  can we make it so that things are trainable?by adding a behavior?
  How does this behavior's update loop block others?
  perhaps actors have a "blocking state" member that
  gets all the updates when set

  Should behaviors being blocked listen to messages?

  This sounds like a good idea. Benefits:
  - we get a uniqueId
  - the thing tracks it's own build progress
  - we can give it a callback to alert when it's done rather
    than having the thing build it, mind it
  - When an scv builds something it could go into a blocking
    state until the thing it is building is finished or
    canceled
    - though it could stop building it?
  - this behavior could be cronoboostable
  - switching to orbital command center needs a blocking state
  - morphing to broods/banes/archons
  - nothing needs to track them if they are buildings. they are
   updated as normal actors and fire a callback when done ###


class Actor
  @blockingBehavior = undefined

  update: ->
    if @blockingBehavior isnt undefined
      @blockingBehavior()
    else
      loopdedoop()
