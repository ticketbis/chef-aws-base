
class Chef
  class AwsEc2

    module Credentials
      def aws_credentials
        access_key_id = new_resource.access_key_id unless new_resource.nil?
        access_key_id = node[:aws][:_t][:access_key_id] unless node[:aws].nil? and node[:aws][:_t].nil? or node[:aws][:_t][:access_key_id].nil?
        access_key_id = node[:aws][:access_key_id] unless node[:aws].nil? or node[:aws][:access_key_id].nil?
        secret_access_key = new_resource.secret_access_key unless new_resource.nil?
        secret_access_key = node[:aws][:_t][:secret_access_key] unless node[:aws].nil? and node[:aws][:_t].nil? or node[:aws][:_t][:secret_access_key].nil?
        secret_access_key = node[:aws][:secret_access_key] unless node[:aws].nil? or node[:aws][:secret_access_key].nil?
        Aws::Credentials.new(access_key_id, secret_access_key)
      end
      def aws_region
        r = new_resource.region unless new_resource.nil?
        r = node[:aws][:_t][:region] unless node[:aws].nil? or node[:aws][:_t].nil? or node[:aws][:_t][:region].nil?
        r = node[:aws][:region] unless node[:aws].nil? or node[:aws][:region].nil?
        r
      end
    end

    def self.get_client(credentials, region)
      Aws::EC2::Client.new(region: region, credentials: credentials)
    end

    def self.get_vpc(name, client)
      return nil unless client
      vpc = client.describe_vpcs(filters: [{ name: 'tag:Name', values: [name] }])[:vpcs].first
      return Aws::EC2::Vpc.new vpc[:vpc_id], client: client unless vpc.nil?
      nil
    end

    def self.get_vpc_igw(name, client)
      get_vpc(name, client).internet_gateways.first
    end

    def self.get_nat_machine(client, name, vpc_id, region = nil)
      filter = [{ name: 'tag:Name', values: [name] }, { name: 'vpc-id', values: [vpc_id] }]
      filter << { name: 'tag:nat', values: [true] }
      filter << { name: 'availability-zone', values: [region] } if region
      i = client.describe_instances(filters: filter)[:vpcs].first
      return Aws::EC2::Instance.new i[:instance_id], client: client unless i.nil?
      nil
    end

    def self.get_route_table(vpc, name, client = nil)
      fail "Client needed if VPC name passed" if vpc.instance_of?(String) && !client
      vpc = get_vpc vpc, client if vpc.instance_of? String
      return nil unless vpc
      vpc.route_tables.select do |rt|
        rt.tags.any? { |t| t.key == 'Name' && t.value == name}
      end.first
    end

    def self.get_subnet vpc, name, client=nil
      fail "Client needed if VPC name passed" if vpc.instance_of?(String) && !client
      vpc = get_vpc vpc, client if vpc.instance_of? String
      return nil unless vpc
      vpc.subnets.select do |s|
        s.tags.any? { |t| t.key == 'Name' && t.value == name}
      end.first
    end

    def self.get_free_eip client, allow_create=true
      return nil unless client.instance_of? Aws::EC2::Client
      free = client.describe_addresses(filters: [{ name: 'domain', values: ['vpc'] }]).addresses.find{|a| a.association_id.nil?}
      return free unless free.nil?
      return nil unless allow_create
      a = client.allocate_address(domain: 'vpc')
      client.describe_addresses(allocation_ids: [a.allocation_id]).addresses.first
    end

    def self.get_security_group vpc, name, client=nil
      fail "Client needed if VPC name passed" if vpc.instance_of?(String) && !client
      vpc = get_vpc vpc, client if vpc.instance_of? String
      return nil unless vpc
      vpc.security_groups.select { |s| s.group_name == name }.first
    end

    def self.get_keypair(name, client=nil)
      begin client.describe_key_pairs(key_names: [name]).key_pairs.first
      rescue Aws::EC2::Errors::InvalidKeyPairNotFound
      end
    end

    def self.get_instance(name, subnet)
      return nil if subnet.nil?
      subnet.instances.select{|i| i.tags.any?{|t| t.key == 'Name' and t.value == name}}.first
    end

    def self.get_image(region, name)
      return nil if region.nil? or name.nil?
      return name if /^ami-/ =~ name
      res = case name.to_s
      when 'nat'
        case region
        when 'us-east-1' then 'ami-b0210ed8'
        when 'eu-west-1' then 'ami-ef76e898'
        end
      end
      fail "Cannot found image '#{name.to_s}' in region '#{region}'" if res.nil?
      res
    end

    def self.get_iam_client(credentials, region)
      Aws::IAM::Client.new region: region, credentials: credentials
    end

    def self.get_certificate(name, client)
      begin
        t = client.get_server_certificate(server_certificate_name: name)
      rescue
        nil
      else
        Aws::IAM::ServerCertificate.new(name, client: client)
      end
    end

    def self.get_elb_client(credentials, region)
      Aws::ElasticLoadBalancing::Client.new region: region, credentials: credentials
    end

  end
end


