require 'spec_helper'

require 'json'

describe "API proxy" do

  it "Should pass a get to the API" do
    get '/apiproxy/topologies'
    last_response.should be_ok
    response_json = JSON.parse(last_response.body)
    response_json.should include("all")
  end

end
