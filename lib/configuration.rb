require 'yaml'
def load_configuration()
	YAML.load_file('config.yml')
end