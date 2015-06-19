actions :create, :delete

default_action :create

attribute :name, kind_of: String, name_attribute: true
attribute :region, kind_of: String
attribute :access_key_id, kind_of: String
attribute :secret_access_key, kind_of: String
