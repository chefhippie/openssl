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
default["openssl"]["organization"] = "Webhippie"
default["openssl"]["expiration"] = 1095

default["openssl"]["ca"]["name"] = "ca"
default["openssl"]["ca"]["source"] = "data_bag"
default["openssl"]["ca"]["organization"] = node["openssl"]["organization"]
default["openssl"]["ca"]["expiration"] = node["openssl"]["expiration"]
