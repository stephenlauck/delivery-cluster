source 'https://supermarket.chef.io'

metadata

cookbook 'chef-server', git: 'https://github.com/stephenlauck/chef-server.git', branch: 'add_org_and_user'

group :integration do
  cookbook 'test', path: './test/fixtures/cookbooks/test'
end