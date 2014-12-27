#
# Cookbook Name:: openssl
# Provider:: ca
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

require "chef/dsl/include_recipe"
include Chef::DSL::IncludeRecipe

action :create do
  directory cert_path.to_s do
    recursive true
    action :create
  end

  case new_resource.source
  when "generate"
    template cert_info.to_s do
      owner "root"
      group "root"
      mode 0640

      cookbook "openssl"
      source "ca.info.erb"

      variables(
        "organization" => new_resource.organization,
        "expiration" => new_resource.expiration
      )
    end

    bash "openssl_ca_#{new_resource.name}_key" do
      code <<-EOH
        certtool --generate-privkey \
          --outfile #{key_file.to_s}
      EOH

      action :run

      not_if do
        key_file.exist?
      end
    end

    bash "openssl_ca_#{new_resource.name}_cert" do
      code <<-EOH
        certtool --generate-self-signed \
          --template #{cert_info.to_s} \
          --load-privkey #{key_file.to_s} \
          --outfile #{cert_file.to_s}
      EOH

      action :run

      not_if do
        cert_file.exist?
      end
    end

    file key_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode "0640"

      action :create
    end

    file cert_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode "0644"

      action :create
    end

    new_resource.updated_by_last_action(true)
  when "data_bag"
    file key_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode "0640"
      content cert_bag["key"]

      action :create

      not_if do
        cert_bag["key"].nil?
      end
    end

    file key_file.to_s do
      action :delete

      only_if do
        cert_bag["key"].nil?
      end
    end

    file cert_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode "0644"
      content cert_bag["cert"]

      action :create

      not_if do
        cert_bag["cert"].nil?
      end
    end

    file cert_file.to_s do
      action :delete

      only_if do
        cert_bag["cert"].nil?
      end
    end

    new_resource.updated_by_last_action(true)
  end
end

action :delete do
  directory cert_path.to_s do
    recursive true
    action :delete
  end

  new_resource.updated_by_last_action(true)
end

def cert_path
  @cert_path ||= Pathname.new(
    node["openssl"]["cert_path"]
  ).join(
    new_resource.name
  )
end

def cert_info
  cert_path.join("certtool.info")
end

def cert_file
  cert_path.join("cert.pem")
end

def key_file
  cert_path.join("key.pem")
end

def cert_bag
  @cert_bag ||= begin
    data_bag_item(
      node["openssl"]["data_bag"],
      new_resource.name
    ).tap do |entries|
      [
        node["fqdn"],
        node["domain"],
        node["hostname"],

        "default"
      ].each do |key|
        return entries[key] unless entries[key].nil?
      end
    end
  end
end
