require 'spec_helper'

require 'json'

describe "API proxy" do

  it "Should pass a get to the API" do
    get '/apiproxy/topologies'
    last_response.should be_ok
    response_json = JSON.parse(last_response.body)
    response_json.should include("all")
  end

  it "Should pass a delete to the API" do
    delete '/apiproxy/topologies/9999'
    response_json = JSON.parse(last_response.body)
    response_json["error_message"].should include("Couldn't find Topology with ")
    last_response.status.should be(400)
  end

  it "Should pass a put to the API" do
    put '/apiproxy/topologies/9999?operation=deploy'
    response_json = JSON.parse(last_response.body)
    response_json["error_message"].should include("Couldn't find Topology with ")
    last_response.status.should be(400)
  end
end
