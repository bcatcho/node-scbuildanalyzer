function RunSim() {
	var data = [];

	function unit(min, gas, supply, buildTime) {
		return {
			cost: cost(min, gas),
			supply: supply,
			buildTime: buildTime,
		};
	}

	var stats = {
		probe: unit(50, 0, 1, 17),
		pylon: unit(100, 0, 10, 17)
	};

	var state = {
		nextWorkerBuildTime: stats.probe.buildTime,
		workers: 6,
		totalMin: 0,
		supply: 6,
		supplyCap: 10,
		supplyBuildTime: 0,
		buildingSupply: false
	}

	function cost(min, gas) {
		return {
			m: min,
			g: gas
		}
	};

	function addWorker(time) {
		state.workers += 1;
		state.nextWorkerBuildTime = time + stats.probe.buildTime;
		state.totalMin -= stats.probe.cost.m;
		state.supply += stats.probe.supply;
	}

	function remainingSupply() {
		return state.supplyCap - state.supply;
	}

	function buildSupply(time) {
		state.buildingSupply = true;
		state.supplyBuildTime = time + stats.pylon.buildTime;
		state.totalMin -= stats.pylon.cost.m;
	}

	function updateBuildSupply(time) {
		if (state.buildingSupply && time >= state.supplyBuildTime) {
			state.buildingSupply = false;
			state.supplyCap += stats.pylon.supply;
		}
	}

	function canAfford(unit) {
		return state.totalMin >= unit.cost.m
	}

	data.push([0, 0]);
	data.push([0, 0]);

	for (var t = 1; t < 600; ++t) {

		updateBuildSupply(t);

		if (remainingSupply() < 3 && ! state.buildingSupply && canAfford(stats.pylon)) {
			buildSupply(t);
		}

		if (t >= state.nextWorkerBuildTime && canAfford(stats.probe) && remainingSupply() > 0) {
			addWorker(t);
		}


		var minPerSec = (40 / 60) * state.workers;
		state.totalMin += minPerSec;
		data[1].push([t, state.totalMin]);
    
    data[0].push([t, 40*state.workers]);
  }

	var options = {
		zoom: {
			interactive: true
		},
		pan: {
			interactive: true
		}
	};

	$.plot($("#placeholder"), data, options);
}

$(function() {
	RunSim();
})

