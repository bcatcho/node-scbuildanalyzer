## The Goal
Comparing the effects of changes to a build order through the use of graphs and other imagry.
- Graphs need context. What do the numbers mean? How can you best convey to a bronze-plat the meaning of a 2 minute
  delay in expansion?
- Perhaps one way of showing what a number means is to show the relative value of it in terms of what it can buy
  - Hover over 150 min, see it in terms of marines, or tanks, lings, etc somehwere on the page.

## What this means for design
- We need the ability to generate multiple graphs and compare them, second for second.
- Choosing when to build supply is difficult. 
  Early in the game you can cut it close, but later in the game you often must build it 10 supply ahead. 
  I will ignore this for now and always build supply 3 food in advance.

How will we add buildings into the build order decision tree?
- A simple dictionary of (time, building) pairs should be good

## Initial prototype decisions

## Modeling Worker Mineral Collection
More Research: [http://wiki.teamliquid.net/starcraft2/Protoss_Unit_Statistics][http://wiki.teamliquid.net/starcraft2/Protoss_Unit_Statistics]
Some research:[http://wiki.teamliquid.net/starcraft2/Mining**Minerals][some research]
- Mineral patches are the bottleneck
  The first two workers on a patch will collect 40 min/sec, the 3rd will collect 20.
  3 workers per patch is all a patch can sustain due to travel time.

## Design Scratchpad

Actor
   behaviors *

Behavior
   properties *
   states *
   methods *

State
   updateLoop
   messages *


Actors have no properties/methods by default

Actor.say
   Tell one of the behaviors something
   This may be a method on the behavior or one of it's properties

Actor.get
   get the result of a method or property
