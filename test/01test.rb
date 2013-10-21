testcase.mock_server("s1") do |server|
  server.rxreq
  server.txresp
end

testcase.client_testcase("c1","-connect ${s1_sock} ") do |test|
  test.txreq
  test.rxresp
end

testcase.server do |server|
  server.wait("s1")
end

testcase.run
