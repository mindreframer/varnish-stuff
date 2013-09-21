require './lib/varnishtest_base'

testcase = Urushiol::VarnishTestBase.new("third test")

testcase.mock_server("s1") do |server|
  server.rxreq
  server.expect "req.request == PUT"
  server.expect "req.proto == HTTP/1.0"
  server.expect "req.url == \"/foo\""
  server.txresp do |resp|
    resp.message "Foo"
    resp.status_code "201"
    resp.protocol "HTTP/1.2"
  end
end

testcase.client_testcase("c1","-connect ${s1_sock} ") do |test|
  test.txreq do |req|
    req.url "/foo"
    req.protocol "HTTP/1.0"
    req.request "PUT"
  end
  test.rxresp
  test.expect "resp.proto == HTTP/1.2"
  test.expect "resp.status == 201"
  test.expect "resp.msg == Foo"
end

testcase.server do |server|
  server.wait("s1")
end

testcase.run
