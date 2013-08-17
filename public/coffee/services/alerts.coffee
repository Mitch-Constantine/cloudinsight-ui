app.factory 'manageAlerts', ()->
	(alertsArray)->
		alertsModule = 
		    closeAlert : (index)->this.splice(index, 1)
		    error : (msg)->this.push({type:'error', msg:msg})
		    success : (msg)->this.push({type:'success', msg:msg})
		    warn : (msg)->this.push({msg:msg})
		    hide : (message)-> 
		    	index = _.indexOf(this, message)
		    	this.closeAlert(index) if index != -1
		    display : (message)-> 
		    	this.splice(0, 0, message) unless this.isDisplayed(message)
			isDisplayed : (message)-> 
				_.indexOf(this, message) > 0
		 _.extend alertsArray, alertsModule