# See https://docs.getchef.com/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "delivery"
client_key               "#{current_dir}/delivery.pem"
validation_client_name   "chef_delivery-validator"
validation_key           "#{current_dir}/chef_delivery-validator.pem"
chef_server_url          "https://chef.example.com/organizations/chef_delivery"
cookbook_path            ["#{current_dir}/../cookbooks"]
