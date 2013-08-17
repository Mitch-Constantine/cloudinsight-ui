# From https://gist.github.com/sente/1083506 (massaged to use CoffeeScript and Angular.js)

@app.factory 'formatXml', ()->
	return (xml)->
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
