@TopologyGridController = ($scope, $cookieStore, $parse, timeFunctions, config, topologies, manageAlerts)->

    $scope.main_alerts = []
    manageAlerts($scope.main_alerts)

    $scope.config = config

    success =  (data)->
        $scope.topologies = data
        showCurrentPage()
        rebuildSelectedItems()
        $scope.main_alerts.hide(cantConnectError)

    rebuildSelectedItems = ()->
        oldSelection = _.clone( $scope.gridOptions.selectedItems )
        $scope.gridOptions.selectedItems.length = 0
        for row, index in $scope.topologies
            if _.findWhere(oldSelection, {id:row.id})
                $scope.gridOptions.selectedItems.push(row)

    failure = ()->
        $scope.main_alerts.display(cantConnectError)
    
    timeFunctions.setInterval( (()-> topologies.get( success, failure )), 3000)

    $scope.pagingOptions = 
        pageSizes: [2, 5, 10, 50, 100]
        pageSize: 50
        currentPage: 1

    $scope.filterOptions = 
        filterText: ""
        useExternalFilter: true

    $scope.totalTopologies = 0    


    $scope.$watch('pagingOptions', ((newVal, oldVal) ->
        if (newVal != oldVal && newVal.currentPage != oldVal.currentPage) 
          showCurrentPage())
    , true)
    $scope.$watch('filterText', (newVal, oldVal) ->
        if (newVal != oldVal) 
            $scope.pagingOptions.currentPage = 1
            showCurrentPage()       
    , true)

    oldSortName = ""
    oldSortDirection = ""
    $scope.$on 'ngGridEventSorted', (ev, sortedColumn)->
        newSortName = sortedColumn.fields?[0]
        newSortDirection = sortedColumn.directions?[0]

        if newSortName != oldSortName or newSortDirection != oldSortDirection
            $scope.pagingOptions.currentPage = 1
            oldSortName = newSortName
            oldSortDirection = newSortDirection
            showCurrentPage() 

    $scope.currentPage = []

    showCurrentPage = ()->
        return unless $scope.topologies

        sortedTopologies = performSorting($scope.topologies)
        filteredTopologies = performFiltering(sortedTopologies)
        $scope.totalTopologies = filteredTopologies.length
        $scope.currentPage.splice(0, $scope.currentPage.length)
        startIndex = $scope.pagingOptions.pageSize * ($scope.pagingOptions.currentPage-1)
        if startIndex >= $scope.totalTopologies
            startIndex = 0
            $scope.pagingOptions.currentPage = 1
        for i in [1..Math.min($scope.pagingOptions.pageSize, $scope.totalTopologies-startIndex)]
            $scope.currentPage.push(filteredTopologies[startIndex + i-1])
        $scope.currentPage = _.clone($scope.currentPage)

    performSorting = (topologies)->
        sortField = oldSortName
        return topologies unless sortField

        sortFunction = parseFilter(sortField)
        return topologies unless sortFunction

        sorted = _.sortBy(topologies, sortFunction)
        if oldSortDirection == "desc"
            sorted.reverse()
        return sorted

    performFiltering  = (topologies)-> 
        return topologies unless $scope.filterText
        parsedFilter = parseFilter($scope.filterText)
        return if parsedFilter then (topology for topology in topologies when satisfiesFilter(parsedFilter, topology)) else topologies

    satisfiesFilter = (filter, topology)->
        try
            filter(topology)
        catch e
            false

    parseFilter = (expr)->
        try
            $parse(expr)
        catch e
            null               

    $scope.gridOptions = {
        data : 'currentPage',
        columnDefs: [
            {field:'id', displayName:'Id', width:50},
            {field:'name', displayName:'Name',
            cellTemplate:
                """<div class=\"ngCellText\" ng-class=\"col.colIndex()\">
                    <span ng-cell-text>
                        <div class='pull-right'>
                            <img src='images/errorIcon.png' 
                                 ng-show='row.getProperty(\"deployment.status\")==\"failed\"' 
                                 title='{{row.getProperty(\"deployment.error\")}}'>
                            <span ng-show='row.getProperty(\"deployment.status\")==\"deploying\"'>
                                [Deploying {{deployment_time(row.getProperty(\"id\"))|date:'mm:ss'}}....]
                            </span>
                        </div>
                        <a ng-click=\"rename(row.entity)\">{{row.getProperty(col.field)}}</a>
                    </span>
                </div>"""},
            {field:'nodes.length', displayName:'Nodes', width:100},
            {field:'appUrl', displayName:'Application URL', 
            cellTemplate:"<div class=\"ngCellText colt{{$index}}\"><a href='{{row.getProperty(col.field)}}' target='_blank'>{{row.getProperty(col.field)}}</a></div>" }
        ],
        showSelectionCheckbox : true,
        selectWithCheckboxOnly : true,
        showColumnMenu : true,
        showHeader : true,
        showFooter : true,
        enablePaging : true,
        pagingOptions : $scope.pagingOptions,
        filterOptions : $scope.filterOptions,
        selectedItems : [],
        plugins: [new ngGridFlexibleHeightPlugin()],
        enableColumnResize : true,
        enableColumnReordering : true,
        useExternalSorting : true,
        rowTemplate:'''
                    <div style="height: 100%" ng-class="row.getProperty(\'deployment.status\')">
                        <div 
                            ng-style="{ \'cursor\': row.cursor }" 
                            ng-repeat="col in renderedColumns" 
                            ng-class="col.colIndex()" 
                            class="ngCell ">
                            <div 
                                class="ngVerticalBar" 
                                ng-style="{height: rowHeight}" 
                                ng-class="{ ngVerticalBarVisible: !$last }"> 
                            </div>
                            <div ng-cell></div>
                        </div>
                    </div>
                    '''  
    }

    $scope.deployment_time = (id)->
        now = new XDate()
        startTime = getStartTime(id)
        return if startTime then Math.floor(startTime.diffMilliseconds(now)) else null

    getStartTime = (id)->
        cookieValue = $cookieStore.get("startTime_" + id)
        return if cookieValue then new XDate(cookieValue) else null

    $scope.deleteTopology = ()->topologies.delete $scope.gridOptions.selectedItems

    updateDeploymentTime = ()->
        deploymentInProgress = _.find( $scope.currentPage, (t)->t.deployment.status == "deploying")
        if deploymentInProgress
            $scope.$digest() unless $scope.$$phase
    timeFunctions.setInterval(updateDeploymentTime, 5000)

    $scope.deployTopology = ()-> performMassOperation('deploy', 'Deploy')
    $scope.undeployTopology = ()-> performMassOperation('undeploy', 'Undeploy')
    $scope.repairTopology = ()-> performMassOperation('repair', 'Repair')

    performMassOperation = (operation, operationName)->
        prefix = operationName + ' ' + topology.name + ': '
        onStart = $scope.main_alerts.warn(prefix + 'Operation started')
        onFailure = $scope.main_alerts.error(response?.data?.error_message or "Operation failed - no error message available")
        topologies.performMassOperation($scope.gridOptions.selectedItems, operation, onStart, onFailure)

    $scope.rename = (topology)->edit(topology)
    $scope.newTopology = ()->edit({isNew:true})

    edit = (topology)->
        $scope.topologyToEdit = topology
        $scope.originalTopology = _.clone topology

    cantConnectError = {type: 'error', msg: 'Connection to server was lost'}

