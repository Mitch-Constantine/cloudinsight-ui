app = angular.module('cloudInsightUI', ['ngResource', 'ui.bootstrap', 'ngUpload', 'ngGrid'])

app.controller 'TopologyGridController', ($scope, $resource, $timeout)->

	$scope.main_alerts = []

	Topologies = $resource('/apiproxy/topologies')
	refreshTopology = ()-> Topologies.get( {}, success, failure ) 

	success =  (data)->
		if changed( $scope.topologies, data.all)
			$scope.topologies = data.all
		hideUnableToConnect()
		reschedule()

	changed = (first, second) -> JSON.stringify(first) != JSON.stringify(second)

	failure = ()->
		displayUnableToConnect()
		reschedule()

	reschedule = ()->$timeout(refreshTopology, 3000)

	refreshTopology()

	$scope.gridOptions = {
		data : 'topologies',
		columnDefs: [{field:'name', displayName:'Name'}],
		showSelectionCheckbox : true,
		selectWithCheckboxOnly : true,
		selectedItems : []
	}

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
						error(response?.data?.error_message or "Operation failed - no error message available")
				)


	getSelectedIds = ()->
		selectedTopologies = $scope.gridOptions.selectedItems
		selectedIds = _.pluck(selectedTopologies, "id")


	$scope.rename = (topology)-> 
		$scope.topologyToEdit = topology
		$scope.originalTopology = _.clone topology

	$scope.newTopology = ()->
		$scope.topologyToEdit = {isNew : true}
		$scope.originalTopology = {}

	$scope.closeAlert = (index)->$scope.main_alerts.splice(index, 1)
	error = (msg)->$scope.main_alerts.push({type:'error', msg:msg})
	hideUnableToConnect = ()-> if (isCantConnectDisplayed()) then $scope.closeAlert(0)
	displayUnableToConnect = ()-> unless(isCantConnectDisplayed()) then $scope.main_alerts.splice(0, 0, cantConnectError)

	isCantConnectDisplayed = ()->$scope.main_alerts[0] == cantConnectError
	cantConnectError = {type: 'error', msg: 'Connection to server was lost'}

app.controller 'ModalEditTopologyController', ($scope, $window, $resource,$q)->
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