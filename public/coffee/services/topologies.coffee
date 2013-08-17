app.factory 'topologies', ($resource, $cookieStore)->

    Topologies = $resource('/apiproxy/topologies')
    
    topologies =
        get : (success, failure)->

            processTopologies = (data)->
                topologies = data.all
                setRowStatus(topologies)
                setStartTime(topologies)
                setAppUrl(topologies)
                success(topologies)
            Topologies.get( {}, processTopologies, failure )
            
            setRowStatus = (topologies)->
                for topology in topologies
                    topology.status = topology?.deployment?.status

            setStartTime = (topologies)->
                currentTime = (new XDate()).toString()
                for topology in topologies
                    cookieKey = "startTime_" + topology.id
                    if topology?.deployment?.status == 'deploying'
                        $cookieStore.put(cookieKey, currentTime) unless $cookieStore.get(cookieKey)
                    else
                        $cookieStore.remove(cookieKey)

            setAppUrl = (topologies)->
                for topology in topologies
                    applications = topology?.deployment?.applications
                    if applications 
                        appWithUrl = _.find applications, (app)->app.url
                        topology.appUrl = appWithUrl?.url

        delete : (topologies)->
            for topology in topologies
                Topology = $resource('/apiproxy/topologies/:id', {id:topology.id})
                Topology.delete()

        performMassOperation : (topologies, operation, onStart, onFailure)->
            for topology in topologies
                Topology = $resource(
                        '/apiproxy/topologies/:id?operation=:operation', 
                        {id:topology.id, operation:operation}, 
                        {put : {method : "PUT"}}
                )
                onStart(topology)
                Topology.put(null, (->), onFailure)


        save : (topology, originalTopology, success, failure)->
            
            update = ()->
                operations = []
                if originalTopology.name != topologyToEdit.name
                    Topology = $resource(
                        '/apiproxy/topologies/:id?operation=:operation&name=:name', 
                        {
                            id:topologyToEdit.id, 
                            operation:"rename", 
                            name : $scope.topologyToEdit.name
                        }, 
                        {
                            put : {method : "PUT"}
                        })
                    operations.push Topology.put(null).$promise
                if originalTopology.description != topologyToEdit.description
                    Topology = $resource(
                        '/apiproxy/topologies/:id?operation=:operation&description=:description', 
                        {
                            id:topologyToEdit.id, 
                            operation:"update_description", 
                            description : topologyToEdit.description
                        }, 
                        {
                            put : {method : "PUT"}
                        })
                    operations.push Topology.put(null).$promise
                    $q.all(operations).then(success, failure)

            createNew = ()->
                Topologies = $resource('/apiproxy/topologies?name=:name&description=:description', 
                    {
                        name: topologyToEdit.name ? "",
                        description: topologyToEdit.description ? ""
                    })
                Topologies.save {definition : topologyToEdit.pattern}, success, failure

            if topology.id then update() else createNew()

        


            

