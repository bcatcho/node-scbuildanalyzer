chai = require 'chai'
chai.should()
expect = chai.expect

econ = require '../coffee/sim.econ.coffee'

util = 
  wrkr: -> new econ.Worker
  min: -> new econ.MineralPatch

describe 'EconSim', ->
  it 'sets up', ->
    sim = new econ.EconSim 6
    sim.bases.length.should.equal 6 


describe 'EconSim MineralPatch', ->
  it 'sets up', ->
    min = new econ.MineralPatch
    min.amt.should.be.a 'number'

  it 'attaches new workers that target it via event', ->
    min = new econ.MineralPatch
    min.$ay 'attachWorker', util.wrkr()
    min.workers.length.should.equal 1

  it 'subtract minerals on mineralsHarvested event', ->
    min = new econ.MineralPatch
    expectedAmt = min.amt - 5
    min.$ay 'mineralsHarvested', 5
    min.amt.should.equal expectedAmt

describe 'EconSim Worker', ->
  it 'takes time to travel', ->
    wrkr = new econ.Worker
    wrkr.should.equal 'create test'
