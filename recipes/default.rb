package 'libvarnishapi-dev'
package 'libmicrohttpd-dev'
package 'automake'
package 'pkg-config'
package 'libcurl3'
package 'libcurl3-gnutls'
package 'libcurl4-openssl-dev'
package 'python-docutils'

#create dir
directory "#{node['varnish-dashboard']['dir']}/agent" do
    mode 0755
    owner "#{node['user']}"
    group "#{node['user']}"
    action :create
    recursive true
end

git "#{node['varnish-dashboard']['dir']}/agent" do
  repository "git://github.com/varnish/vagent2.git"
  reference "master"
  action :sync
end

execute "Install Varnish Agent 2 (autogen)" do
  cwd "#{node['varnish-dashboard']['dir']}/agent"
  user "root"
  command "./autogen.sh"
end

execute "Install Varnish Agent 2 (configure)" do
  cwd "#{node['varnish-dashboard']['dir']}/agent"
  user "root"
  command "./configure"
end

execute "Install Varnish Agent 2 (make)" do
  cwd "#{node['varnish-dashboard']['dir']}/agent"
  user "root"
  command "make"
end

execute "Install Varnish Agent 2 (make install)" do
  cwd "#{node['varnish-dashboard']['dir']}/agent"
  user "root"
  command "make install" 
end

template "#{node['varnish']['dir']}/agent_secret" do
  source "varnish-agent-secret.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, "service[varnish]"
end

git "#{node['varnish-dashboard']['dir']}/dashboard" do
	repository "git://github.com/pbruna/Varnish-Agent-Dashboard.git"
	reference "master"
	action :sync
end

execute "Start the varnish agent" do
   cwd "#{node['varnish-dashboard']['dir']}/agent"
   user "root"
   command "varnish-agent -H #{node['varnish-dashboard']['dir']}/dashboard -n #{node['varnish']['instance']}"
end