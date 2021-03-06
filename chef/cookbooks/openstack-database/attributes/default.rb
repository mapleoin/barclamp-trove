#
# Cookbook Name:: openstack-database
# Recipe:: default
#
# Copyright 2013-2014 SUSE Linux GmbH
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

# Set to some text value if you want templated config files
# to contain a custom banner at the top of the written file
default["openstack"]["database"]["custom_template_banner"] = "
# This file autogenerated by Chef
# Do not edit, changes will be overwritten
"

default["openstack"]["database"]["verbose"] = false
default["openstack"]["database"]["debug"] = false

default["openstack"]["database"]["syslog"]["use"] = false

default["openstack"]["database"]["user"] = "trove"
default["openstack"]["database"]["group"] = "trove"

case platform
when "suse"
  default["openstack"]["database"]["platform"] = {
    "api_packages" => [ "openstack-trove-api" ],
    "api_service" => "openstack-trove-api",
    "conductor_packages" => [ "openstack-trove-conductor" ],
    "conductor_service" => "openstack-trove-conductor",
    "taskmanager_packages" => [ "openstack-trove-taskmanager" ],
    "taskmanager_service" => "openstack-trove-taskmanager",
    "guestagent_packages" => [ "openstack-trove-guestagent" ],
    "guestagent_service" => "openstack-trove-guestagent",
  }
end

default["openstack"]["database"]["db"]["username"] = "trove"

default["openstack"]["database"]["service_user"] = "trove"
default["openstack"]["database"]["service_role"] = "admin"
default["openstack"]["database"]["service_tenant_name"] = "service"
default["openstack"]["database"]["region"] = "RegionOne"

default["openstack"]["database"]["volume_support"] = true

# Keystone PKI signing directory
default["openstack"]["trove"]["api"]["auth"]["cache_dir"] = "/var/cache/trove/api"

default["openstack"]["database"]["nova_proxy_user"] = "admin"
default["openstack"]["database"]["nova_proxy_password"] = "admin"
default["openstack"]["database"]["nova_proxy_tenant"] = "admin"
