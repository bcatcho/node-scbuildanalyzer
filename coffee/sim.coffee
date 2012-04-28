root = exports ? this
SCSim = root.SCSim

runSim = (harvesterCount, simLength = 600) ->
  simTickLength = simLength / SCSim.config.secsPerTick
  tickToDate = (t) -> new Date(t * 1000)
  
  logs =
    mineralsCollected: []

  simRun = new SCSim.SimRun
  sim = simRun.sim
  simRun.emitter.observe 'mineralsCollected',
     (e) => logs.mineralsCollected.push [e.time.sec, e.args[0]/(e.time.sec/60)]
     

  console.profile()
  base = sim.makeActor "nexus"
  sim.say 'start'
  base.say("trainUnit", 'probe') for i in [1..harvesterCount]

  simRun.update() for i in [1..simTickLength]
  console.profileEnd()

  results =
     data: []
     markings: []

  dataFirstPass = []
  # TODO make config setting, this just happens to look cool
  dataChunkTime = (25)

  perChunkToPerMin = (amt) -> amt * (60/dataChunkTime)
  for e in logs.mineralsCollected
    time = Math.floor(e[0] / dataChunkTime)
    if dataFirstPass[time] is undefined
      dataFirstPass[time] = {time: tickToDate(time * dataChunkTime),  amt: 0}
    dataFirstPass[time].amt += 5

  results.data = ([d.time, perChunkToPerMin(d.amt)] for n, d of dataFirstPass)
  return results


options =
  grid:
    borderWidth: 0
    markings: []
  xaxis:
    mode: "time"
    timeformat: "%M:%S"

series = []

addSeries = (series, options, harvesterCount) ->
  results = runSim harvesterCount, 800
  series.push
    data: results.data
    shadowSize: 0
    lines:
      lineWidth: 2
  options.grid.markings = options.grid.markings.concat results.markings
  {series, options}

{series, options} = addSeries series, options, 14

$.plot $("#placeholder"), series, options
