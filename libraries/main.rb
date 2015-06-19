
class Chef
  class AwsEc2
    def self.get_client(access_key_id, secret_access_key, region)
      Aws::EC2::Client.new region: region, credentials: Aws::Credentials.new(access_key_id, secret_access_key)
    end

    def self.get_vpc(name, client)
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

    def self.get_security_group vpc, name, client=nil
      fail "Client needed if VPC name passed" if vpc.instance_of?(String) && !client
      vpc = get_vpc vpc, client if vpc.instance_of? String
      return nil unless vpc
      vpc.security_groups.select { |s| s.group_name == name }.first
    end

    def self.get_iam_client(access_key_id, secret_access_key, region)
      Aws::IAM::Client.new region: region, credentials: Aws::Credentials.new(access_key_id, secret_access_key)
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

    def self.get_elb_client(access_key_id, secret_access_key, region)
      Aws::ElasticLoadBalancing::Client.new region: region, credentials: Aws::Credentials.new(access_key_id, secret_access_key)
    end

  end
end

