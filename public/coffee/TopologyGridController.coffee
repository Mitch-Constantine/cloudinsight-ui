angular.module('cloudInsightUI', ['ngResource', 'ui.bootstrap', 'ngUpload'])
.controller 'TopologyGridController', ($scope, $resource, $timeout)->

	$scope.f = ()->alert('abc')

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

	$scope.deployTopology = ()-> performMassOperation('deploy')
	$scope.undeployTopology = ()-> performMassOperation('undeploy')
	$scope.repairTopology = ()-> performMassOperation('repair')

	performMassOperation = (operation)->
		_.each $scope.topologies, (topology)->topology.error = null
		_.each getSelectedIds(), (id)->
			Topology = $resource('/apiproxy/topologies/:id?operation=:operation', {id:id, operation:operation}, {put : {method : "PUT"}})
			Topology.put(null,
					->,
					(response)->
						topology = _.findWhere $scope.topologies, {id:id}
						topology.error = response.data.error_message
				)


	getSelectedIds = ()->
		selectedTopologies = _.where($scope.topologies, {checked : true})
		selectedIds = _.pluck(selectedTopologies, "id")


	$scope.rename = (topology)-> 
		$scope.topologyToEdit = topology
		$scope.originalTopology = _.clone topology

	$scope.newTopology = ()->
		$scope.topologyToEdit = {isNew : true}
		$scope.originalTopology = {}

window.ModalEditTopologyController = ($scope, $window, $resource,$q)->
	$scope.alerts = []

	$scope.close = ()-> 
		# hack for issues with closing dialogs. WIP by angular-ui team 
		# https://github.com/angular-ui/bootstrap/issues/441
		# $scope.topologyToEdit = null
		$window.location.reload()
	$scope.save = ()->
			if $scope.topologyToEdit.isNew
				createNew()
			else
				doEdit()

	createNew = ()->
		Topologies = $resource('/apiproxy/topologies?name=:name&description=:description', 
			{name:$scope.topologyToEdit.name, description: $scope.topologyToEdit})
		Topologies.save {definition : $scope.topologyToEdit.pattern},
			()->$scope.close(),
			(response)->
				error response?.data?.error_message or "Operation failed - no error message available"
	doEdit = ()->	
		operations = []
		if $scope.originalTopology.name != $scope.topologyToEdit.name
			Topology = $resource('/apiproxy/topologies/:id?operation=:operation&name=:name', 
				{id:$scope.topologyToEdit.id, operation:"rename", name : $scope.topologyToEdit.name}, {put : {method : "PUT"}})
			operations.push Topology.put(null).$promise
		if $scope.originalTopology.description != $scope.topologyToEdit.description
			Topology = $resource('/apiproxy/topologies/:id?operation=:operation&description=:description', 
				{id:$scope.topologyToEdit.id, operation:"update_description", description : $scope.topologyToEdit.description}, {put : {method : "PUT"}})
			operations.push Topology.put(null).$promise

		$q.all(operations).then($scope.close)

	$scope.closeAlert = (index)->$scope.alerts.splice(index, 1)

	success = (msg)->$scope.alerts.push({type:'success', msg:msg})
	error = (msg)->$scope.alerts.push({type:'error', msg:msg})

	$scope.uploadComplete = (response, isComplete) -> 
		if !isComplete
			return
		
		if response.id
			success "File was successfully uploaded"
		else
			error( response?.error_message or "Upload failed - no error message available" )