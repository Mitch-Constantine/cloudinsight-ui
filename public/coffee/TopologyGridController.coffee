app = angular.module('cloudInsightUI', ['ngCookies', 'ngResource', 'ui.bootstrap', 'ngUpload', 'ngGrid', 'ui.ace'])

app.controller 'TopologyGridController', ($scope, $resource, $timeout, $cookieStore, $parse)->

    $scope.main_alerts = []

    $scope.config = $resource('/config').get()

    Topologies = $resource('/apiproxy/topologies')
    refreshTopology = ()-> Topologies.get( {}, success, failure ) 

    success =  (data)->
        if changed( $scope.topologies, data.all)
            $scope.topologies = data.all
            setAppUrl()
            formatPattern(data.all)
            setRowStatus(data.all)
            setStartTime(data.all)
            showCurrentPage()
            rebuildSelectedItems()
        hideUnableToConnect()
        reschedule()

    setRowStatus = (all)->
        for topology in all
            topology.status = topology?.deployment?.status

    setStartTime = (all)->
        currentTime = (new XDate()).toString()
        for topology in all
            cookieKey = "startTime_" + topology.id
            if topology?.deployment?.status == 'deploying'
                $cookieStore.put(cookieKey, currentTime) unless $cookieStore.get(cookieKey)
            else
                $cookieStore.remove(cookieKey)

    formatPattern = (all)->
        for topology in all
            topology.pattern = formatXml(topology.pattern) if topology.pattern

    setAppUrl = ()->
        _.each $scope.topologies, (topology)->
            applications = topology?.deployment?.applications
            if applications 
                appWithUrl = _.find applications, (app)->app.url
                topology.appUrl = appWithUrl?.url

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
                            <img src='images/erroricon.png' 
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
        rowTemplate:'<div style="height: 100%" ng-class="row.getProperty(\'deployment.status\')"><div ng-style="{ \'cursor\': row.cursor }" ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell ">' +
                           '<div class="ngVerticalBar" ng-style="{height: rowHeight}" ng-class="{ ngVerticalBarVisible: !$last }"> </div>' +
                           '<div ng-cell></div>' +
                     '</div></div>'     
    }

    $scope.deployment_time = (id)->
        now = new XDate()
        startTime = getStartTime(id)
        return if startTime then Math.floor(startTime.diffMilliseconds(now)) else null

    getStartTime = (id)->
        cookieValue = $cookieStore.get("startTime_" + id)
        return if cookieValue then new XDate(cookieValue) else null

    refreshEverySecond = ()->
        deploymentInProgress = _.find( $scope.currentPage, (t)->t.deployment.status == "deploying")
        if deploymentInProgress
            $scope.$digest() unless $scope.$$phase
        $timeout(refreshEverySecond, 5000)

    refreshEverySecond()

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
                    ->,
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
            {name:$scope.topologyToEdit.name ? "", description: $scope.topologyToEdit.description ? ""})
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

    $scope.$watch 'topologyToEdit', ()->
        if $scope.aceEditor
            $scope.aceEditor.setReadOnly !topologyToEdit.isNew

    $scope.uploadComplete = (response, isComplete) -> 
        if !isComplete
            warn('Upload started')
            return
        
        if response.id
            success "File was successfully uploaded"
        else 
            error( response?.error_message or "Upload failed - no error message available" )


# From https://gist.github.com/sente/1083506 (reformatted to CoffeeScript)
formatXml = (xml)->
    formatted = ''
    xml=xml.replace(/\r\n/g, " ")
    reg = /(>)(\s*)(<)(\/*)/g
    xml = xml.replace(reg, '$1\r\n$3$4');
    pad = 0

    jQuery.each xml.split('\r\n'), (index, node) ->
        indent = 0
        if node.match( /.+<\/\w[^>]*>$/ )
            indent = 0
        else if node.match( /^<\/\w/ )
            if pad != 0
                pad -= 1
        else if node.match( /^<\w[^>]*[^\/]>.*$/ )
            indent = 1
        else 
            indent = 0      
         
        padding = ''
        if pad > 0 # Range one line below reverses direction if pad=0!
            for i in [1..pad]
                padding += '    '
     
        formatted += padding + node + '\r\n'
        pad += indent;
     
    return formatted;
