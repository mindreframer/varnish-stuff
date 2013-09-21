require './lib/varnishtest_base'

testcase = Urushiol::VarnishTestBase.new("forth test")

testcase.mock_server("s1") do |server|
  server.rxreq
  server.txresp do |resp|
    resp.header "Connection: close"
    resp.body "012345"
  end
end

testcase.mock_varnish("v1") do |varnish|
  varnish.vcl_backend 'backend b2 {
		.host = "${s1_addr}";
		.port = "${s1_port}";
	}
  sub vcl_recv {
    set req.backend = b2;
    return(lookup);
}'
end


testcase.client_testcase("c1") do |test|
  test.txreq do |req|
    req.url "/"
  end
  test.rxresp
  test.expect "resp.status == 200"
  test.expect "resp.body == \"012345\""
end

testcase.server do |server|
  server.wait("s1")
end

testcase.run
