#
# Cookbook Name:: trove
# Recipe:: default
#
# Copyright 2014, SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ::Chef::Recipe
  include ::Openstack
end

node.set['openstack']['database']['verbose'] = node[:trove][:verbose]
node.set['openstack']['database']['debug'] = node[:trove][:debug]
node.set['openstack']['database']['volume_support'] = node[:trove][:volume_support]

[['keystone-server', 'identity-api'],
 ['keystone-server', 'identity-admin'],
 ['nova-multi-controller', 'compute-api'],
 ['cinder-controller', 'block-storage-api'],
 ['swift-proxy', 'object-storage-api']
].each do |comp, endpoint|
  instance = get_instance("roles:#{comp}")
  Chef::Log.info("Found #{comp} instance on #{instance}.")
  node.set_unless['openstack']['endpoints'][endpoint] = {}
  node.set['openstack']['endpoints'][endpoint]['host'] = instance['fqdn']
  node.set['openstack']['endpoints'][endpoint]['scheme'] = instance['protocol']
  node.set['openstack']['endpoints'][endpoint]['port'] = instance['service_port']
end

keystone_settings = KeystoneHelper.keystone_settings(node, @cookbook_name)
# talking to nova via the novaclient, this should be an admin user in
# the keystone config (see the attributes in trove-taskmanager.conf and
# others)
node.set['openstack']['database']['nova_proxy_user'] = keystone_settings['admin_user']
node.set['openstack']['database']['nova_proxy_password'] = keystone_settings['admin_password']
node.set['openstack']['database']['nova_proxy_tenant'] = keystone_settings['admin_tenant']

node.set['openstack']['use_databags'] = false
node.set['openstack']['secret']['openstack_identity_bootstrap_token'] = {:token => keystone_settings['admin_token'] }
node.set['openstack']['secret']['database']['db'] = node[:trove][:db][:password]
node.set['openstack']['secret']['database']['user'] = keystone_settings['service_password']
node.set['openstack']['secret']['database']['service'] = keystone_settings['service_password']
node.set['openstack']['database']['service_user'] = keystone_settings['service_user']

node.set_unless['openstack']['endpoints']['database-api'] = {}
node.set['openstack']['endpoints']['database-api']['host'] = node['fqdn']
node.set['openstack']['endpoints']['database-api']['bind-host'] = node['fqdn']

rabbitmq = get_instance('roles:rabbitmq-server')[:rabbitmq]
Chef::Log.info("Found rabbitmq server on #{rabbitmq}.")
node.set['openstack']['mq']['service_type'] = 'rabbitmq'
node.set['openstack']['mq']['database']['rabbit']['host'] = rabbitmq[:address]
node.set['openstack']['mq']['database']['rabbit']['port'] = rabbitmq[:port] if rabbitmq[:port]
# XXX using the 'nova' user and vhost for now
# (upstream default is 'guest' for everything)
# TODO find out what happens if we use a different user/vhost than nova
node.set['openstack']['mq']['database']['rabbit']['userid'] = rabbitmq[:user]
node.set['openstack']['mq']['database']['rabbit']['vhost'] = rabbitmq[:vhost]
node.set['openstack']['secret'][rabbitmq[:user]]['user'] = rabbitmq[:password]

# XXX mysql configuration
# this part should go away once trove supports postgresl

# rubygem-mysql is installed here, although it would normally be the
# database cookbook's responsibility. The database cookbook uses a
# special mysql-chef_gem for this which is Chef 0.11 only.
['mysql', 'python-mysql', 'rubygem-mysql'].each do |pkg|
  package pkg
end

service 'mysql' do
  action [:start, :enable]
end

# copied from openstack-common/database/db_create_with_user
conn = {
    :host => '127.0.0.1',
    :port => 3306,
    :username => 'root',
  }

database 'create trove database' do
  provider ::Chef::Provider::Database::Mysql
  connection conn
  database_name node[:trove][:db][:database]
  action :create
end

# create user
database_user node[:trove][:db][:user] do
  provider ::Chef::Provider::Database::MysqlUser
  connection conn
  password node[:trove][:db][:password]
  action :create
end

# grant privs to user
database_user node[:trove][:db][:user] do
  provider ::Chef::Provider::Database::MysqlUser
  connection conn
  password node[:trove][:db][:password]
  database_name node[:trove][:db][:database]
  host '%'
  privileges [:all]
  action :grant
end

include_recipe 'openstack-database::identity_registration'
include_recipe 'openstack-database::api'
include_recipe 'openstack-database::conductor'
include_recipe 'openstack-database::taskmanager'
