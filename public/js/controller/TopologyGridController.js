(function() {

  this.TopologyGridController = function($scope, $cookieStore, $parse, timeFunctions, config, topologies, manageAlerts) {
    var cantConnectError, edit, failure, getStartTime, oldSortDirection, oldSortName, parseFilter, performFiltering, performMassOperation, performSorting, rebuildSelectedItems, satisfiesFilter, showCurrentPage, success, updateDeploymentTime;
    $scope.main_alerts = [];
    manageAlerts($scope.main_alerts);
    $scope.config = config;
    success = function(data) {
      $scope.topologies = data;
      showCurrentPage();
      rebuildSelectedItems();
      return $scope.main_alerts.hide(cantConnectError);
    };
    rebuildSelectedItems = function() {
      var index, oldSelection, row, _len, _ref, _results;
      oldSelection = _.clone($scope.gridOptions.selectedItems);
      $scope.gridOptions.selectedItems.length = 0;
      _ref = $scope.topologies;
      _results = [];
      for (index = 0, _len = _ref.length; index < _len; index++) {
        row = _ref[index];
        if (_.findWhere(oldSelection, {
          id: row.id
        })) {
          _results.push($scope.gridOptions.selectedItems.push(row));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };
    failure = function() {
      return $scope.main_alerts.display(cantConnectError);
    };
    timeFunctions.setInterval((function() {
      return topologies.get(success, failure);
    }), 3000);
    $scope.pagingOptions = {
      pageSizes: [2, 5, 10, 50, 100],
      pageSize: 50,
      currentPage: 1
    };
    $scope.filterOptions = {
      filterText: "",
      useExternalFilter: true
    };
    $scope.totalTopologies = 0;
    $scope.$watch('pagingOptions', (function(newVal, oldVal) {
      if (newVal !== oldVal && newVal.currentPage !== oldVal.currentPage) {
        return showCurrentPage();
      }
    }), true);
    $scope.$watch('filterText', function(newVal, oldVal) {
      if (newVal !== oldVal) {
        $scope.pagingOptions.currentPage = 1;
        return showCurrentPage();
      }
    }, true);
    oldSortName = "";
    oldSortDirection = "";
    $scope.$on('ngGridEventSorted', function(ev, sortedColumn) {
      var newSortDirection, newSortName, _ref, _ref2;
      newSortName = (_ref = sortedColumn.fields) != null ? _ref[0] : void 0;
      newSortDirection = (_ref2 = sortedColumn.directions) != null ? _ref2[0] : void 0;
      if (newSortName !== oldSortName || newSortDirection !== oldSortDirection) {
        $scope.pagingOptions.currentPage = 1;
        oldSortName = newSortName;
        oldSortDirection = newSortDirection;
        return showCurrentPage();
      }
    });
    $scope.currentPage = [];
    showCurrentPage = function() {
      var filteredTopologies, i, sortedTopologies, startIndex, _ref;
      if (!$scope.topologies) return;
      sortedTopologies = performSorting($scope.topologies);
      filteredTopologies = performFiltering(sortedTopologies);
      $scope.totalTopologies = filteredTopologies.length;
      $scope.currentPage.splice(0, $scope.currentPage.length);
      startIndex = $scope.pagingOptions.pageSize * ($scope.pagingOptions.currentPage - 1);
      if (startIndex >= $scope.totalTopologies) {
        startIndex = 0;
        $scope.pagingOptions.currentPage = 1;
      }
      for (i = 1, _ref = Math.min($scope.pagingOptions.pageSize, $scope.totalTopologies - startIndex); 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        $scope.currentPage.push(filteredTopologies[startIndex + i - 1]);
      }
      return $scope.currentPage = _.clone($scope.currentPage);
    };
    performSorting = function(topologies) {
      var sortField, sortFunction, sorted;
      sortField = oldSortName;
      if (!sortField) return topologies;
      sortFunction = parseFilter(sortField);
      if (!sortFunction) return topologies;
      sorted = _.sortBy(topologies, sortFunction);
      if (oldSortDirection === "desc") sorted.reverse();
      return sorted;
    };
    performFiltering = function(topologies) {
      var parsedFilter, topology, _i, _len, _results;
      if (!$scope.filterText) return topologies;
      parsedFilter = parseFilter($scope.filterText);
      if (parsedFilter) {
        _results = [];
        for (_i = 0, _len = topologies.length; _i < _len; _i++) {
          topology = topologies[_i];
          if (satisfiesFilter(parsedFilter, topology)) _results.push(topology);
        }
        return _results;
      } else {
        return topologies;
      }
    };
    satisfiesFilter = function(filter, topology) {
      try {
        return filter(topology);
      } catch (e) {
        return false;
      }
    };
    parseFilter = function(expr) {
      try {
        return $parse(expr);
      } catch (e) {
        return null;
      }
    };
    $scope.gridOptions = {
      data: 'currentPage',
      columnDefs: [
        {
          field: 'id',
          displayName: 'Id',
          width: 50
        }, {
          field: 'name',
          displayName: 'Name',
          cellTemplate: "<div class=\"ngCellText\" ng-class=\"col.colIndex()\">\n    <span ng-cell-text>\n        <div class='pull-right'>\n            <img src='images/errorIcon.png' \n                 ng-show='row.getProperty(\"deployment.status\")==\"failed\"' \n                 title='{{row.getProperty(\"deployment.error\")}}'>\n            <span ng-show='row.getProperty(\"deployment.status\")==\"deploying\"'>\n                [Deploying {{deployment_time(row.getProperty(\"id\"))|date:'mm:ss'}}....]\n            </span>\n        </div>\n        <a ng-click=\"rename(row.entity)\">{{row.getProperty(col.field)}}</a>\n    </span>\n</div>"
        }, {
          field: 'nodes.length',
          displayName: 'Nodes',
          width: 100
        }, {
          field: 'appUrl',
          displayName: 'Application URL',
          cellTemplate: "<div class=\"ngCellText colt{{$index}}\"><a href='{{row.getProperty(col.field)}}' target='_blank'>{{row.getProperty(col.field)}}</a></div>"
        }
      ],
      showSelectionCheckbox: true,
      selectWithCheckboxOnly: true,
      showColumnMenu: true,
      showHeader: true,
      showFooter: true,
      enablePaging: true,
      pagingOptions: $scope.pagingOptions,
      filterOptions: $scope.filterOptions,
      selectedItems: [],
      plugins: [new ngGridFlexibleHeightPlugin()],
      enableColumnResize: true,
      enableColumnReordering: true,
      useExternalSorting: true,
      rowTemplate: '<div style="height: 100%" ng-class="row.getProperty(\'deployment.status\')">\n    <div \n        ng-style="{ \'cursor\': row.cursor }" \n        ng-repeat="col in renderedColumns" \n        ng-class="col.colIndex()" \n        class="ngCell ">\n        <div \n            class="ngVerticalBar" \n            ng-style="{height: rowHeight}" \n            ng-class="{ ngVerticalBarVisible: !$last }"> \n        </div>\n        <div ng-cell></div>\n    </div>\n</div>'
    };
    $scope.deployment_time = function(id) {
      var now, startTime;
      now = new XDate();
      startTime = getStartTime(id);
      if (startTime) {
        return Math.floor(startTime.diffMilliseconds(now));
      } else {
        return null;
      }
    };
    getStartTime = function(id) {
      var cookieValue;
      cookieValue = $cookieStore.get("startTime_" + id);
      if (cookieValue) {
        return new XDate(cookieValue);
      } else {
        return null;
      }
    };
    $scope.deleteTopology = function() {
      return topologies["delete"]($scope.gridOptions.selectedItems);
    };
    updateDeploymentTime = function() {
      var deploymentInProgress;
      deploymentInProgress = _.find($scope.currentPage, function(t) {
        return t.deployment.status === "deploying";
      });
      if (deploymentInProgress) if (!$scope.$$phase) return $scope.$digest();
    };
    timeFunctions.setInterval(updateDeploymentTime, 5000);
    $scope.deployTopology = function() {
      return performMassOperation('deploy', 'Deploy');
    };
    $scope.undeployTopology = function() {
      return performMassOperation('undeploy', 'Undeploy');
    };
    $scope.repairTopology = function() {
      return performMassOperation('repair', 'Repair');
    };
    performMassOperation = function(operation, operationName) {
      var onFailure, onStart, prefix, _ref;
      prefix = operationName + ' ' + topology.name + ': ';
      onStart = $scope.main_alerts.warn(prefix + 'Operation started');
      onFailure = $scope.main_alerts.error((typeof response !== "undefined" && response !== null ? (_ref = response.data) != null ? _ref.error_message : void 0 : void 0) || "Operation failed - no error message available");
      return topologies.performMassOperation($scope.gridOptions.selectedItems, operation, onStart, onFailure);
    };
    $scope.rename = function(topology) {
      return edit(topology);
    };
    $scope.newTopology = function() {
      return edit({
        isNew: true
      });
    };
    edit = function(topology) {
      $scope.topologyToEdit = topology;
      return $scope.originalTopology = _.clone(topology);
    };
    return cantConnectError = {
      type: 'error',
      msg: 'Connection to server was lost'
    };
  };

}).call(this);
