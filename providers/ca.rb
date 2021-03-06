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
  [
    cert_path.to_s,
    key_path.to_s,
    crl_path.to_s
  ].uniq.each do |name|
    directory name do
      recursive true
      action :create
    end
  end

  case new_resource.source
  when "generate"
    template cert_info.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0640

      cookbook "openssl"
      source "ca.info.erb"

      variables(
        "organization" => new_resource.organization,
        "unit" => new_resource.unit,
        "locality" => new_resource.locality,
        "state" => new_resource.state,
        "country" => new_resource.country,
        "expiration" => new_resource.expiration
      )
    end

    template crl_info.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0640

      cookbook "openssl"
      source "crl.info.erb"

      variables(
        "next_update" => new_resource.next_update
      )
    end

    bash "openssl_ca_#{new_resource.name}_key" do
      code <<-EOH
        certtool --generate-privkey \
          --outfile #{key_file}
      EOH

      action :run

      not_if do
        key_file.exist?
      end
    end

    bash "openssl_ca_#{new_resource.name}_cert" do
      code <<-EOH
        certtool --generate-self-signed \
          --template #{cert_info} \
          --load-privkey #{key_file} \
          --outfile #{cert_file}
      EOH

      action :run

      not_if do
        cert_file.exist?
      end
    end

    bash "openssl_ca_#{new_resource.name}_crl" do
      code <<-EOH
        certtool --generate-crl \
          --template #{crl_info} \
          --load-ca-privkey #{key_file} \
          --load-ca-certificate #{cert_file} \
          --outfile #{crl_file}
      EOH

      action :run

      not_if do
        crl_file.exist?
      end
    end

    file key_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0640

      action :create
    end

    file cert_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0644

      action :create
    end

    file crl_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0644

      action :create
    end

    new_resource.updated_by_last_action(true)
  when "data_bag"
    file key_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0640
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

    file crl_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0644
      content cert_bag["crl"]

      action :create

      not_if do
        cert_bag["crl"].nil?
      end
    end

    file crl_file.to_s do
      action :delete

      only_if do
        cert_bag["crl"].nil?
      end
    end

    file cert_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0644
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
  [
    crl_path.to_s,
    key_path.to_s,
    cert_path.to_s
  ].uniq.each do |name|
    directory name do
      recursive true
      action :delete
    end
  end

  new_resource.updated_by_last_action(true)
end

def key_path
  @key_path ||= key_file.dirname
end

def key_file
  @key_file ||= Pathname.new(new_resource.key_path)
end

def crl_path
  @crl_path ||= crl_file.dirname
end

def crl_file
  @crl_file ||= Pathname.new(new_resource.crl_path)
end

def crl_info
  @crl_info ||= crl_path.join("crl.info")
end

def cert_path
  @cert_path ||= cert_file.dirname
end

def cert_file
  @cert_file ||= Pathname.new(new_resource.cert_path)
end

def cert_info
  @cert_info ||= key_path.join("cert.info")
end

def cert_bag
  @cert_bag ||= begin
    values = {
      key: nil,
      cert: nil,
      crl: nil
    }

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
