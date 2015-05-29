
directory '/etc/chef/trusted_certs' do
  recursive true
end

# execute "scp -i /root/.ssh/insecure_private_key -o StrictHostKeyChecking=no -r root@chef.example.com:/tmp/delivery-validator.pem /etc/chef/validation.pem"

execute "scp -i /root/.ssh/insecure_private_key -o StrictHostKeyChecking=no -r root@chef.example.com:/var/opt/opscode/nginx/ca/chef.example.com.crt  /etc/chef/trusted_certs/chef.example.com.crt"

cookbook_file '/etc/chef/encrypted_data_bag_secret' do
  action :create
  source 'encrypted_data_bag_secret'
end

file "/etc/chef/client.rb" do
 content <<-EOD
log_location     STDOUT
chef_server_url  "https://chef.example.com/organizations/chef_delivery"
client_key '/etc/delivery/delivery.pem'
node_name 'delivery'
trusted_certs_dir "/etc/chef/trusted_certs"
encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"

Dir.glob(File.join("/etc/chef", "client.d", "*.rb")).each do |conf|
  Chef::Config.from_file(conf)
end
 EOD
end

package 'chefdk' do
  action :upgrade
end


file "/opt/delivery/embedded/cookbooks/delivery_build/Berksfile" do
 content <<-EOD
   source "https://supermarket.chef.io"

   metadata

   cookbook 'push-jobs'
 EOD
end

file "/tmp/delivery_builders.rb" do
 content <<-EOD
name "delivery_builders"
description "Delivery builder node role"
run_list "recipe[push-jobs]", "recipe[delivery_build]"
 EOD
 notifies :run, "execute[upload delivery_builders role]"
end

execute 'upload delivery_builders role' do
  cwd '/tmp'
  command 'knife role from file delivery_builders.rb --server-url https://chef.example.com/organizations/chef_delivery --user delivery --key /etc/delivery/delivery.pem --config /etc/chef/client.rb'
  action :nothing
  notifies :run, "execute[chef-client]"
end

# berks vendor cookbooks
execute 'berks vendor cookbooks' do
  cwd '/opt/delivery/embedded/cookbooks/delivery_build'
end

execute 'upload delivery_build cookbooks' do
  cwd '/etc/chef/'
  command 'knife cookbook upload --all --cookbook-path /opt/delivery/embedded/cookbooks/delivery_build/cookbooks --server-url https://chef.example.com/organizations/chef_delivery --user delivery --key /etc/delivery/delivery.pem --config /etc/chef/client.rb --force'
end

execute 'create builder keys data bag' do
  cwd '/etc/chef/'
  command 'knife data bag create keys --secret / --server-url https://chef.example.com/organizations/chef_delivery --user delivery --key /etc/delivery/delivery.pem --config /etc/chef/client.rb'
end

file "/etc/chef/delivery_builder_keys.json" do
 content <<-EOD
{
  "id": "delivery_builder_keys",
   "builder_key":  "#{File.read("/etc/delivery/builder_key")}",
   "delivery_pem": "#{File.read("/etc/delivery/delivery.pem")}"
}
 EOD
 action :create_if_missing
end

execute 'create builder keys data bag' do
  cwd '/etc/chef/'
  command 'knife data bag from file keys delivery_builder_keys.json --secret --server-url https://chef.example.com/organizations/chef_delivery --user delivery --key /etc/delivery/delivery.pem --config /etc/chef/client.rb'
end

file "/etc/chef/first-boot.json" do
 content <<-EOD
   {"run_list":[]"]}
 EOD
 notifies :run, "execute[chef-client]"
end

execute "chef-client"