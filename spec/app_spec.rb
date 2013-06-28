require 'spec_helper'

describe "Sinatra App" do

  it "Root page should be CloudInsight UI main page" do
    get '/'
    last_response.should be_ok
    last_response.body.should include('CloudInsight UI')
  end

  it "Root page should be CloudInsight UI main page" do
    get '/coffee/test.js'
    last_response.should be_ok
    last_response.body.should include 'alert("Test message")'
  end

end
