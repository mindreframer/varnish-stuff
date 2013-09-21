require './lib/varnishtest_base'

testcase = Urushiol::VarnishTestBase.new("second test")

testcase.mock_server("s1") do |server|
  server.rxreq
  server.expect "req.proto == HTTP/1.1"
  server.expect "req.url == \"/\""
  server.txresp do |resp|
    resp.message "Ok"
    resp.status_code "200"
    resp.protocol "HTTP/1.1"
  end
end

testcase.client_testcase("c1","-connect ${s1_sock} ") do |test|
  test.txreq do |req|
    req.url "/"
    req.protocol "HTTP/1.1"
  end
  test.rxresp
  test.expect "resp.proto == HTTP/1.1"
  test.expect "resp.status == 200"
  test.expect "resp.msg == Ok"
end

testcase.server do |server|
  server.wait("s1")
end

testcase.run
