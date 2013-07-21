require 'spec_helper'

describe "Sinatra App" do

  it "Root page should be CloudInsight UI main page" do
    get '/'
    last_response.should be_ok
    last_response.body.should include('CloudInsight UI')
  end

  it "Coffeescript files are translated" do
    get '/coffee/test.js'
    last_response.should be_ok
    last_response.body.should include 'alert("Test message")'
  end

  it "returns configuration on /config" do
    get '/config'
    last_response.should be_ok
    response_json = JSON.parse(last_response.body)
    response_json.should include("server")
    response_json.should include("port")
    response_json.should include("user")
    response_json.should_not include("password")
  end

end
