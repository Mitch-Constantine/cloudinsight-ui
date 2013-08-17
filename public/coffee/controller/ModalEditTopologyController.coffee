app.controller 'ModalEditTopologyController', ($scope, $window, topologies, formatXml,manageAlerts)->

    $scope.alerts = []
    manageAlerts($scope.main_alerts)

    $scope.close = ()-> 
        # hack for issues with closing dialogs. WIP by angular-ui team 
        # https://github.com/angular-ui/bootstrap/issues/441
        # $scope.topologyToEdit = null
        $window.location.reload()

    $scope.save = ()->topologies.save(
        $scope.topologyToEdit, 
        $scope.originalTopology,
        ()->$scope.close(),
        (response)->$scope.alerts.error response?.data?.error_message or "Operation failed - no error message available"
    )

    $scope.$watch 'topologyToEdit', ()->
        if $scope.topologyToEdit
            $scope.topologyToEdit.pattern = formatXml($scope.topologyToEdit.pattern)
            if $scope.aceEditor
                $scope.aceEditor.setReadOnly !topologyToEdit.isNew

    $scope.uploadComplete = (response, isComplete) -> 
        if !isComplete
            $scope.alerts.warn('Upload started')
            return
        
        if response.id
            $scope.alerts.success "File was successfully uploaded"
        else 
            $scope.alerts.error( response?.error_message or "Upload failed - no error message available" )
