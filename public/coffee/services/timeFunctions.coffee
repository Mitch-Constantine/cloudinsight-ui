# Lifted from: http://stackoverflow.com/questions/14237070/using-setinterval-in-angularjs-factory

app.factory 'timeFunctions', [

  "$timeout",

  timeFunctions = ($timeout) ->
    _intervals = []
    _intervalUID = 1

    functions = 
      setInterval : (operation, interval, $scope) ->
        _internalId = _intervalUID++;

        intervalOperation = () ->
          operation( $scope || undefined );
          _intervals[ _internalId ] = $timeout(intervalOperation, interval);

        _intervals[ _internalId ] = $timeout(intervalOperation, interval);
        return _internalId;

      clearInterval: (id)-> $timeout.cancel( _intervals[ id ] )
    
    return functions
]