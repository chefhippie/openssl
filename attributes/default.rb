#
# Cookbook Name:: openssl
# Attributes:: default
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

default["openssl"]["packages"] = %w(
  openssl
  gnutls
)

default["openssl"]["cert_path"] = "/etc/pki"
default["openssl"]["data_bag"] = "openssl"
default["openssl"]["organization"] = ""
default["openssl"]["unit"] = ""
default["openssl"]["locality"] = ""
default["openssl"]["state"] = ""
default["openssl"]["country"] = ""
default["openssl"]["email"] = ""
default["openssl"]["expiration"] = 365
default["openssl"]["self_signing"] = false

default["openssl"]["ca"]["name"] = "ca"
default["openssl"]["ca"]["source"] = "generate"
default["openssl"]["ca"]["cert_path"] = "#{node["openssl"]["cert_path"]}/ca/cert.pem"
default["openssl"]["ca"]["key_path"] = "#{node["openssl"]["cert_path"]}/ca/key.pem"
default["openssl"]["ca"]["crl_path"] = "#{node["openssl"]["cert_path"]}/ca/crl.pem"
default["openssl"]["ca"]["organization"] = node["openssl"]["organization"]
default["openssl"]["ca"]["unit"] = node["openssl"]["unit"]
default["openssl"]["ca"]["locality"] = node["openssl"]["locality"]
default["openssl"]["ca"]["state"] = node["openssl"]["state"]
default["openssl"]["ca"]["country"] = node["openssl"]["country"]
default["openssl"]["ca"]["expiration"] = node["openssl"]["expiration"] * 5
