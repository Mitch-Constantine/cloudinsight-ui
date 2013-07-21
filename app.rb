require "coffee-script"
require 'sinatra'
require 'sinatra/multi_route'
require 'json'

require './lib/proxy'
require './lib/configuration'

config = load_configuration()

set :views, Proc.new { root }

get '/' do
  File.read('public/index.html')
end

get "/coffee/*.js" do
  filename = params[:splat].first
  coffee "public/coffee/#{filename}".to_sym
end

get "/config" do
	return_config = config.clone
	return_config.delete "password"
	content_type :json
	return_config.to_json
end

route :get, :post, :delete, :put, "/apiproxy/*" do
	result = passThroughToApi config, params, request
	status result[:status]
	result[:body]
end
