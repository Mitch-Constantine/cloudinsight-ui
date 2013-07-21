app = angular.module('cloudInsightUI', ['ngResource', 'ui.bootstrap', 'ngUpload', 'ngGrid'])

app.controller 'TopologyGridController', ($scope, $resource, $timeout)->

	$scope.main_alerts = []

	$scope.config = $resource('/config').get()

	Topologies = $resource('/apiproxy/topologies')
	refreshTopology = ()-> Topologies.get( {}, success, failure ) 

	success =  (data)->
		if changed( $scope.topologies, data.all)
			$scope.topologies = data.all
			setAppUrl()
			rebuildSelectedItems()
		hideUnableToConnect()
		reschedule()

	setAppUrl = ()->
		_.each $scope.topologies, (topology)->
			applications = topology?.deployment?.applications
			if applications 
				appWithUrl = _.find applications, (app)->app.url
				if appWithUrl
					topology.appUrl = appWithUrl.url

	rebuildSelectedItems = ()->
		oldSelection = _.clone( $scope.gridOptions.selectedItems )
		$scope.gridOptions.selectedItems.length = 0
		for row, index in $scope.topologies
			if _.findWhere(oldSelection, {id:row.id})
				$scope.gridOptions.selectedItems.push(row)

	changed = (first, second) -> JSON.stringify(first) != JSON.stringify(second)

	failure = ()->
		displayUnableToConnect()
		reschedule()

	reschedule = ()->$timeout(refreshTopology, 3000)

	refreshTopology()

	$scope.gridOptions = {
		data : 'topologies',
		columnDefs: [
			{field:'id', displayName:'Id', width:50},
			{field:'name', displayName:'Name',
			cellTemplate:"<div class=\"ngCellText\" ng-class=\"col.colIndex()\"><span ng-cell-text><a ng-click=\"rename(row.entity)\">{{row.getProperty(col.field)}}</a></span></div>"},
			{field:'nodes.length', displayName:'Nodes', width:100},
			{field:'appUrl', displayName:'Application URL', 
			cellTemplate:"<div class=\"ngCellText colt{{$index}}\"><a href='{{row.getProperty(col.field)}}' target='_blank'>{{row.getProperty(col.field)}}</a></div>" }
		],
		showSelectionCheckbox : true,
		selectWithCheckboxOnly : true,
		selectedItems : []
	}

	$scope.deleteTopology = ()->
		_.each $scope.gridOptions.selectedItems, (topology)->
			Topology = $resource('/apiproxy/topologies/:id', {id:topology.id})
			Topology.delete()

	$scope.deployTopology = ()-> performMassOperation('deploy', 'Deploy')
	$scope.undeployTopology = ()-> performMassOperation('undeploy', 'Undeploy')
	$scope.repairTopology = ()-> performMassOperation('repair', 'Repair')

	performMassOperation = (operation, operationName)->
		_.each $scope.gridOptions.selectedItems, (topology)->
			prefix = operationName + ' ' + topology.name + ': '
			warn(prefix + 'Operation started')
			Topology = $resource('/apiproxy/topologies/:id?operation=:operation', {id:topology.id, operation:operation}, {put : {method : "PUT"}})
			Topology.put(null,
					->message_success(prefix + 'Operation successful'),
					(response)->
						error(response?.data?.error_message or "Operation failed - no error message available")
				)

	$scope.rename = (topology)-> 
		$scope.topologyToEdit = topology
		$scope.originalTopology = _.clone topology

	$scope.newTopology = ()->
		$scope.topologyToEdit = {isNew : true}
		$scope.originalTopology = {}

	$scope.closeAlert = (index)->$scope.main_alerts.splice(index, 1)
	error = (msg)->$scope.main_alerts.push({type:'error', msg:msg})
	message_success = (msg)->$scope.main_alerts.push({type:'success', msg:msg})
	warn = (msg)->$scope.main_alerts.push({msg:msg})
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
	warn = (msg)->$scope.alerts.push({msg:msg})

	$scope.uploadComplete = (response, isComplete) -> 
		if !isComplete
			warn('Upload started')
			return
		
		if response.id
			success "File was successfully uploaded"
		else
			error( response?.error_message or "Upload failed - no error message available" )