def whyrun_supported?
  true
end

use_inline_resources

action :create do
  converge_by "Setting AWS default credentials" do
    node.default[:aws] ||= {}
    node.default[:aws][:_t] ||= {}
    node.default[:aws][:_t][:access_key_id] = new_resource.access_key_id unless new_resource.access_key_id.nil?
    node.default[:aws][:_t][:secret_access_key] = new_resource.secret_access_key unless new_resource.secret_access_key.nil?
    node.default[:aws][:_t][:region] = new_resource.region unless new_resource.region.nil?
  end
end

action :delete do
  converge_by 'Unsetting AWS default credentials' do
    node.default[:aws].delete(:_t) unless node[:aws].nil?
  end
end
