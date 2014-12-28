#
# Cookbook Name:: openssl
# Provider:: cert
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
    csr_path.to_s,
    key_path.to_s
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
      source "cert.info.erb"

      variables(
        "organization" => new_resource.organization,
        "unit" => new_resource.unit,
        "locality" => new_resource.locality,
        "state" => new_resource.state,
        "country" => new_resource.country,
        "cn" => new_resource.cn,
        "email" => new_resource.email,
        "expiration" => new_resource.expiration,

        "dns_names" => new_resource.dns_names,
        "ip_addresses" => new_resource.ip_addresses,
        "nc_permit_dns" => new_resource.nc_permit_dns,
        "nc_exclude_dns" => new_resource.nc_exclude_dns
      )
    end

    bash "openssl_cert_#{new_resource.name}_key" do
      code <<-EOH
        certtool --generate-privkey \
          --outfile #{key_file}
      EOH

      action :run

      not_if do
        key_file.exist?
      end
    end

    if new_resource.self_signing
      bash "openssl_cert_#{new_resource.name}_cert" do
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
    else
      bash "openssl_cert_#{new_resource.name}_csr" do
        code <<-EOH
          certtool --generate-request \
            --template #{cert_info} \
            --load-privkey #{key_file} \
            --outfile #{csr_file}
        EOH

        action :run

        not_if do
          csr_file.exist?
        end
      end

      bash "openssl_cert_#{new_resource.name}_cert" do
        code <<-EOH
          certtool --generate-certificate \
            --template #{cert_info} \
            --load-request #{csr_file} \
            --load-ca-certificate #{ca_cert} \
            --load-ca-privkey #{ca_key} \
            --outfile #{cert_file}
        EOH

        action :run

        not_if do
          cert_file.exist?
        end
      end

      file csr_file.to_s do
        owner new_resource.owner
        group new_resource.group
        mode 0644

        action :create
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

    file csr_file.to_s do
      owner new_resource.owner
      group new_resource.group
      mode 0644
      content cert_bag["csr"]

      action :create

      not_if do
        cert_bag["csr"].nil?
      end
    end

    file csr_file.to_s do
      action :delete

      only_if do
        cert_bag["csr"].nil?
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
    key_path.to_s,
    csr_path.to_s,
    cert_path.to_s
  ].uniq.each do |name|
    directory name do
      recursive true
      action :delete
    end    
  end

  new_resource.updated_by_last_action(true)
end

def ca_cert
  new_resource.ca_cert
end

def ca_key
  new_resource.ca_key
end

def key_path
  @key_path ||= key_file.dirname
end

def key_file
  @key_file ||= Pathname.new(new_resource.key_path)
end

def csr_path
  @csr_path ||= csr_file.dirname
end

def csr_file
  @csr_file ||= Pathname.new(new_resource.csr_path)
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
      csr: nil
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
        values.merge(entries[key]) unless entries[key].nil?
      end
    end

    values
  end
end
