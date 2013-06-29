require 'lib/configuration.rb'

describe "Configuration system" do
	it "Returns configuration data" do
		config = load_configuration()
		config["server"].should_not be nil
		config["port"].should_not be nil
		config["user"].should_not be nil
		config["password"].should_not be nil
	end
end