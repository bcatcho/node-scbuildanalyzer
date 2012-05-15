## Classes
- Actor
  - behaviors 
  - **notes**
    * They have no behavior/properties/methods by default.
    * Actors are behavior aggregates

- Behavior
  - properties
  - states
  - methods
  - __special methods__
    - `@defaultState` a state named default
    - `@noopUpdate` a dummy update function for states that don't need one
    - `@say`
    - `@sayAfter`
  - __special properties__
    - `@time`
    - `@sim`
    - `@actor`
    - `@simId`
  - **notes**
    * Behaivors do everything interesting

- State
  - updateLoop
  - messages
  - enterState
  - **notes**
    * A state is used by a behavior.

- Event
  - startTime
  - endTime (most likely)
  - dependantEvent

## Challenges

#### AI Decision making

The decisions need to based on incoming **data**. The data must be useful to answer these questions:

1. When to build supply?
2. When to build harvesters?
3. When to take gas?
4. When to stop building these things?
5. When to execute the next part of the build?
6. When to cronoboost?
7. Can I build X yet?

The datas that a __player__ uses to make these decisions in the real Starcraft is

1. How much supply do I have? What do I need to make in the next X minutes
2. See #1. Do I have the cash?
3. Am I reaching my saturation limit on minerals?
4. What is next in my build order?
5. Do I have crono? Am I saving it? Is the last thing still being cronoed?
6. Do I have the right tech tree open to build X?
7. How much time is left till X upgrade or tech path opens up?

## Program Flow

Examine data >> Decide >> Act >> Compute X ticks >> Gather Data >> Repeat

It may be easier to Gather data as we go. When certain events fire it could log it immediately.

For example

     Buy unit x -> deduct resources, supply
     Building X Built -> Open up tech tree, add supply, etc
     Gas/Min Harvested -> Affect resources
     Cronoboost available -> update available cronoboost
     Cronoboost spell disipates -> place in data.AlertPool or something
     Things being built/researched/Trained -> place in data.Building/researching/Training Pool
      so that they can be checked on by AI
     harvesters stop harvesting -> AlertPool

**Idea** - the data collector will be in charge of which events it listens to and what it does with those events.
  The simulation will not have any logging in it explicitly.

## TODO

- Conventions on when to "say" something to yourself, as an object. This affects logging
  
  Thought: never do anything interesting in the update loop, just check the need for a state change?
  
  Or: Only do state changes outside of the update loop. Say 'X' to switch to state X.
  
  Only: Say when other objects are involved?


## Optimisations

- Event logs. Instead of searching to see if an event needs to be logged, maybe attach a method to the event itself that does the logging.

## Scratch

What will the rules for the "Smarts" look like?
Normally a player builds things based on:
   - a specific time
   - a spectif food
   - when something else is done

There will be competing priorities between:
   - making probes and the next thing of your build
   - making supply and probes and the next thing

Some things will often be automatic but at times you wish to change the timing of one or two
   - probes
   - supply
     - this may require a cool predictive measure to determine when to build supply so as to not get blocked if you have 10 gates.
