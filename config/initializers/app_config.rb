# Load application configuration
require 'ostruct'
require 'yaml'
Syck::Syck = Syck
config = YAML.load_file("#{Rails.root}/config/config.yml") || {}
app_config = config['common'] || {}
app_config.update(config[Rails.env] || {})
h2ostruct = lambda do | recurse, object |
  return case object
  when Hash
    object = object.clone
    object.each do |key, value|
      object[key] = recurse.call(recurse, value)
    end
    OpenStruct.new(object)
  when Array
    object = object.clone
    object.map! { |i| recurse.call(recurse, i) }
  else
    object
  end
end
AppConfig = h2ostruct[h2ostruct, app_config]
