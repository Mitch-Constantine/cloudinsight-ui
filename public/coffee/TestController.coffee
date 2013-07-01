angular.module('cloudInsightUI', ['ngResource']);

window.TestController = ($scope, $resource, $timeout)->

	Topologies = $resource('/apiproxy/topologies')
	refreshTopology = ()-> Topologies.get( {}, success, failure ) 

	success =  (data)->
		transferSelection(data.all, $scope.topologies)
		$scope.topologies = data.all
		$scope.failed = false
		reschedule()

	failure = ()->
		$scope.failed = true
		reschedule()

	reschedule = ()->$timeout(refreshTopology, 3000)

	transferSelection = (newData, oldData) ->
		_.each newData, (topology) ->
			if oldData
				oldTopology = _.findWhere(oldData, {id : topology.id})
				topology.checked = oldTopology && oldTopology.checked
				topology.error = oldTopology && oldTopology.error
			else
				topology.checked = false
				topology.error = null

	refreshTopology()

	$scope.deleteTopology = ()->
		_.each getSelectedIds(), (id)->
			Topology = $resource('/apiproxy/topologies/:id', {id:id})
			Topology.delete()

	$scope.deployTopology = ()->
		_.each getSelectedIds(), (id)->
			Topology = $resource('/apiproxy/topologies/:id?operation=deploy', {id:id}, {put : {method : "PUT"}})
			Topology.put(null,
					->,
					(response)->
						topology = _.findWhere $scope.topologies, {id:id}
						topology.error = response.data.error_message
				)


	getSelectedIds = ()->
		selectedTopologies = _.where($scope.topologies, {checked : true})
		selectedIds = _.pluck(selectedTopologies, "id")

