require 'net/http'

def passThroughToApi(config, params)
	path = "/api/" + params[:splat][0]
	req = Net::HTTP::Get.new(path)

	req.basic_auth config["user"], config["password"]

	res = Net::HTTP.start(config["server"], config["port"]) {|http|
	  response = http.request(req)
	  response.body
	}
end