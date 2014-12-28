#
# Cookbook Name:: openssl
# Resource:: cert
#
# Copyright 2013-2014, Thomas Boerger <thomas@webhippie.de>
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

actions :create, :delete

attribute :name, :kind_of => String, :name_attribute => true
attribute :source, :kind_of => String, :default => "generate"
attribute :owner, :kind_of => String, :default => "root"
attribute :group, :kind_of => String, :default => "root"

attribute :cert_path, :kind_of => String, :default => "/etc/pki/dummy/cert.pem"
attribute :key_path, :kind_of => String, :default => "/etc/pki/dummy/key.pem"
attribute :csr_path, :kind_of => String, :default => "/etc/pki/dummy/csr.pem"

attribute :ca_cert, :kind_of => String, :default => node["openssl"]["ca"]["cert_path"]
attribute :ca_key, :kind_of => String, :default => node["openssl"]["ca"]["key_path"]

attribute :organization, :kind_of => String, :default => ""
attribute :unit, :kind_of => String, :default => ""
attribute :locality, :kind_of => String, :default => ""
attribute :state, :kind_of => String, :default => ""
attribute :country, :kind_of => String, :default => ""
attribute :cn, :kind_of => String, :default => ""
attribute :email, :kind_of => String, :default => ""
attribute :expiration, :kind_of => Integer, :default => 1095

attribute :dns_names, :kind_of => Array, :default => []
attribute :ip_addresses, :kind_of => Array, :default => []
attribute :nc_permit_dns, :kind_of => Array, :default => []
attribute :nc_exclude_dns, :kind_of => Array, :default => []

attribute :self_signing, :kind_of => [TrueClass, FalseClass], :default => false

default_action :create
