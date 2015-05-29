# delivery_builders role

directory '/etc/chef/trusted_certs' do
  recursive true
end

execute "scp -i /root/.ssh/insecure_private_key -o StrictHostKeyChecking=no -r root@chef.example.com:/tmp/delivery-validator.pem /etc/chef/validation.pem"

execute "scp -i /root/.ssh/insecure_private_key -o StrictHostKeyChecking=no -r root@chef.example.com:/var/opt/opscode/nginx/ca/chef.example.com.crt  /etc/chef/trusted_certs/chef.example.com.crt"

cookbook_file '/etc/chef/encrypted_data_bag_secret' do
  action :create
  source 'encrypted_data_bag_secret'
end

file "/etc/chef/client.rb" do
 content <<-EOD
log_location     STDOUT
chef_server_url  "https://chef.example.com/organizations/chef_delivery"
validation_client_name "chef_delivery-validator"
validation_key '/etc/chef/validation.pem'
# Using default node name (fqdn)
trusted_certs_dir "/etc/chef/trusted_certs"
encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"

Dir.glob(File.join("/etc/chef", "client.d", "*.rb")).each do |conf|
  Chef::Config.from_file(conf)
end
 EOD
end

file "/etc/chef/first-boot.json" do
 content <<-EOD
   {"run_list":[ "role[delivery_builders]"]}
 EOD
 notifies :run, "execute[chef-client -j first-boot.json]"
end

execute "chef-client -j first-boot.json" do
  action :nothing
end

execute "chef-client"