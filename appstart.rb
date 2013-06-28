require "coffee-script"
require 'sinatra'

set :views, Proc.new { root }

get '/' do
  File.read('public/index.html')
end

get "/coffee/*.js" do
  filename = params[:splat].first
  coffee "public/coffee/#{filename}".to_sym
end
