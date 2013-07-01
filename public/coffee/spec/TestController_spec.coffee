describe "Test Controller", ->
	
	scope = null
	httpBackend = null
	beforeEach inject( ($rootScope, $controller, $httpBackend, $resource) ->
        scope = $rootScope.$new()
        httpBackend = $httpBackend
        httpBackend.when("GET", "/apiproxy/technologies").respond([all : [{name : 'Technology 1'}]])
        $controller('TestController', {
            $scope: scope,
            $resource : $resource
        })
    )

	it "Loads data from $resource", ->	 	 
	        it "should have 3 movies", ->
	            httpBackend.flush()
	            expect(scope.technologies.all[0].name).toBe('Technology 1')
