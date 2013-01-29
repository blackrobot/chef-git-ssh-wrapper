#
# Cookbook Name:: git_ssh_wrapper
# Provider:: default
#
# Copyright 2013, Damon Jablons
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

action :create do
  # Upload the deploy key
  file rsa_key do
    content new_resource.key
    owner new_resource.owner
    group new_resource.group
    mode 0600
    action :create_if_missing
  end

  # Create the SSH wrapper
  template git_wrapper do
    cookbook "git-ssh-wrapper"
    source "wrapper_ssh.erb"
    owner new_resource.owner
    group new_resource.group
    mode 0550
    variables :rsa_key => rsa_key
    action :create_if_missing
  end

  # Create the export in the profile if provided
  if new_resource.profile
    profile_export = "export GIT_SSH='#{git_wrapper}'"

    ruby_block "insert_line" do
      block do
        file = Chef::Util::FileEdit.new(new_resource.profile)
        file.insert_line_if_no_match("/#{profile_export}/", profile_export)
        file.write_file
      end
    end
  end
end

action :delete do
  [git_wrapper, rsa_key].each do |ssh_file|
    file ssh_file do
      action :delete
    end
  end
end

def git_wrapper
  ::File.join(new_resource.path, "#{new_resource.name}_ssh")
end

def rsa_key
  ::File.join(new_resource.path, "#{new_resource.name}_rsa")
end
