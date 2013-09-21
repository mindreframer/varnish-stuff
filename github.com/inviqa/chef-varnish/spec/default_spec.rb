require 'chefspec'

describe 'chef-varnish::default' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'chef-varnish::default' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
