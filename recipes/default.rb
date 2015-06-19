#
# Cookbook Name:: aws-base
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

chef_gem 'aws-sdk' do
  compile_time true
end

require 'aws-sdk'

class Aws::EC2::Subnet
  def hash
    id.hash
  end
  def eql? other
    return false unless other.instance_of? self.class
    return id == other.id
  end
  alias == eql?
end

class Aws::EC2::SecurityGroup
  def hash
    id.hash
  end
  def eql? other
    return false unless other.instance_of? self.class
    return id == other.id
  end
  alias == eql?
end

