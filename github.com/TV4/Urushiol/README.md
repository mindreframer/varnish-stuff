Urushiol - /ʊˈruːʃi.ɒl/ v1.0.1
========

Test framework written in Ruby to test varnish-cache routing and caching logic.

>The sap of the lacquer tree, today bearing the technical description of "urushiol-based lacquer," has traditionally been used in Japan. As the substance is poisonous to the touch until it dries, the creation of lacquerware has long been practiced only by skilled dedicated artisans.

Urushiol was born out of necessity. When we decided to migrate our reverse proxy routing from Apache to Varnish we noticed that this would not be a trivial matter.
As the migration came to a halt due to unexpected routing errors we decided that, having a proper way of testing our configs would not be a bad idea. 
Urushiol is the product of that idea.

####Get up and running with Urushiol.
To start with there are some dependencies that must be satisfied. 
* Varnish (a.t.m only supports 3.0.4) must be installed on the host computer. 
* Ruby ( >= 1.9.2) must be installed on the host computer
* Rubygems (>= 1.8) to install the gem

To install Urushiol just type `gem install urushiol` and you're set to go.

Then there is just the matter of writing the tests, which of course Urushiol can do for you; at least get you started.
Type the following:

```bash
$ urushiol generate NameOfTestHere
NameOfTestHere.uru successfully created.
```

and it will generate a test-skeleton for you. Looking inside `NameOfTestHere.uru` we se this: 

```bash
$ cat NameOfTestHere.uru
# Welcome to Urushio! We have created a testcase instance for you.
# Access it by calling methods on the variable "testcase", like so:
#
#  testcase.mock_server "s1" do |server|
#    server.rxreq
#    server.txresp
#  end
#
#  testcase.run
#
# If you have any questions regarding functionality we redirect you to our Github page:
# https://github.com/TV4/Urushiol
#
# Run this test by running `urushiol NameOfTestHere.uru` in your shell.

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
```

Now to running that test, simply type `urushiol NameOfTestHere.uru` as stated in the testfile and see it succeed.
If it fails try typing `urushiol integritycheck` to see how urushiol is feeling. If any of the checks fail, please check your version of varnish and adhere to 
the requirements stated above.

####Writing your own tests.
Now to write your own tests. It is assumed that you have a varnish `.vcl` file that you want to test.
Each test is written in ruby, and contained within an `.uru` file by convention 
but any readable file containing ruby code will do.

Tests can run in three states: 

The first is a generic state where you must create your own varnish implimentation and mock servers to go with it alongside writing testcode for them.

The second is a 'mock' state where a varnish instance will be created with the specified vcl-file, given as an argument, and where Urushiol mocks the backends in that file to returning 200 status codes 
and the backend name as the body response. This state is great for unit-testing routing logic within the vcl file.

The third state is 'live'. This state is identical to the second state but leaves the backends as they are. This means that if a request is sent to backend A and 
that backend points at a live server, the request will be sent to that server. This state is great for integration-tests and to check that the configured cache logics of
the vcl file is on par with what the actual servers return (such as cache headers etc). Also for testing that your varnish server can access the servers.

While testing in live and mock states Urushiol will handle the backends (mock or real) and the acutal instance of varnish. What you as a user have to do is to provide test cases.

Upon execution the test will be given a test case object to perform operations on. The two main methods that are interesting to you as a 
tester are `client_testcase` which takes a block and yields a client_testcase to do operations upon; as seen below:

```ruby
testcase.client_testcase "c1" do |test|
  test.txreq do |req|
    req.host "superbackend.tv4.se"
  end
  test.rxresp
  test.expect "resp.status == 200"
  test.expect "resp.body == SuperBackend"
end
```

and the `run` method which should be the last thing you write in every test case.

What acutally happens here is that you create a client test case. You mock a client and tell it to send a request to the varnish 
instance, then listen for a response and check conditions on that response. If all conditions are met that test case succeeds.
An .uru file should be seen as a context, within which one can have multiple tests. Each of these should be related to the context 
which in turn is stated in the name of the file. 

As such, if I wanted to test routing for a specific server say our 'super-backend' I would name the .uru file : superbackend_routing.uru

When i feel content with my test coverage after specifying 30 diferent client test cases I finish everything of by running the test case by invoking 
the `run` method.

`testcase.run`

and that should be it.

Now to run the test i would give Urushiol a state flag; a vcl file reference; the .uru file, which would look something like this:

`urushiol --mock /path/to/awesome.vcl /path/to/superbackend_routing.uru`

Urushiol now preforms the tests and gives you a result; a yay if success or a stack trace if the test case fails. 

There is of course more you can do here; test advanced cache logic at the same time as routing with http authentication etc. 
Check the source code to see what is given and if you find something missing, send us an email or do it yourself by forking; fixing; submitting pull request.

Happy hacking!
