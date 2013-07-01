require 'net/http'

def passThroughToApi(config, params,request)
	path = "/api/" + params[:splat][0]
	if request.query_string && request.query_string.length > 0
		path = path + "?" + request.query_string 
	end
	if request.request_method == 'GET'
		req = Net::HTTP::Get.new(path)
	elsif request.request_method == 'DELETE'
		req = Net::HTTP::Delete.new(path)
	elsif request.request_method == 'PUT'
		req = Net::HTTP::Put.new(path)
	end
	req.basic_auth config["user"], config["password"]

	res = Net::HTTP.start(config["server"], config["port"]) {|http|
	  response = http.request(req)
	  {:body => response.body, :status => response.code}
	}
end