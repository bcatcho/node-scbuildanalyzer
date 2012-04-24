## Classes
-  Actor
   -  behaviors 
   -  **notes**
      They have no behavior/properties/methods by default.
      Actors are behavior aggregates

-  Behavior
   -  properties{}
   -  states
   -  methods
   -  __special methods__
      -  `@defaultState` a state named default
      -  `@noopUpdate` a dummy update function for states that don't need one
      -  `@say`
      -  `@sayAfter`
   -  __special properties__
      -  `@time`
      -  `@sim`
      -  `@actor`
      -  `@simId`
   -  **notes**
      Behaivors do everything interesting

-  State
   -  updateLoop()
   -  messages{}
   -  enterState()
   -  **notes**
      A state is used by a behavior.

## Challenges

#### AI Decision making

The decisions need to based on incoming **data**. The data must be useful to answer these questions:
1. When to build supply?
2. When to build workers?
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
