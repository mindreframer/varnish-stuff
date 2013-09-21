Urushiol - /ʊˈruːʃi.ɒl/ v0.5 BETA
========

Test framework written in Ruby to test varnish-cache routing and caching logic.

>The sap of the lacquer tree, today bearing the technical description of "urushiol-based lacquer," has traditionally been used in Japan. As the substance is poisonous to the touch until it dries, the creation of lacquerware has long been practiced only by skilled dedicated artisans.

Urushiol was born out of necessity. When we decided to migrate our reverse proxy routing from Apache to Varnish we noticed that this would not be a trivial matter.
As the migration came to a halt due to unexpected routing errors we decided that, having a proper way of testing our configs would not be a bad idea. 
Urushiol is the product of that idea.

####Get up and running with Urushiol.
To start with there are some dependencies that must be satisfied. 
* Varnish (a.t.m only supports 3.0.4) must be installed on the host computer. 
* Ruby (tested on 1.9.3) must be installed on the host computer

Then there is just the matter of writing the tests. The project come bundled with some examples but lets look at the basics a bit more in depth.

Navigate to the project folder where you will se a folder: `Testing-Framework/` inside there you will se a `lib/` catalog and some `.rb` files that all follow the pattern `0Xtest.rb` these are the function-tests.
You should run each one of them to make sure that the framework actually work, if it doesn't I redirect you back to the dependencies.
You run Urushiol tests by for example typing `ruby 01test.rb` in your shell. You should be presented with `#     top  TEST /tmp/test.vtc passed (0.003)`
each and every time.

####Writing your own tests.
Now to write your own tests. It is assumed that you have a varnish `.vcl` file that you want to test.
Each test is written in ruby and requires `varnishtest_base.rb` which can be found in the `lib` folder within `Testing-Framework` like so: `require './lib/varnishtest_base'` for the functiontests.
From here on you have all the power of Urushiol at your fingertips.

Start out with instanciating a testcase like so:

`testcase = Urushiol::VarnishTestBase.new("vcl test")`

and that's it now you have a testcase you can run by calling `testcase.run`. At the moment that will be pretty uneventfull so lets load up a vcl-fil and mock some backends.
Urushiol has functionallity to do this on the fly. Simply `modified_vcl_file = testcase.mock_backends( vcl_file_path )`.
The `mock_backends` methods does a lot of things but in essence it takes the vcl's filepath and mocks upp servers to act as its backends and modifies the backends in the file to point to the given servers.
Now it's quite easy to test them as they will return statuscode 200 and the backend name as the body.
The method returns a modified version of the vclfile that has the backends rerouted to the mock_servers.

You can create your own servers with the `mock_server` method but that is covered extencivly in the function-tests.

To create a mock varnish one runs the `mock_varnish` method. To configure it one gives it a block of stuff to do. In this case we want to give it a vcl file; the modified vcl file.

```ruby
testcase.mock_varnish "v1" do |varnish|
  varnish.vcl modified_vcl_file
end
```

This starts a mock varnish with the given configfile and it works just as a real varnish would, because it is a real varnish instance.

So now we have servers, and a varnish instance that points at the servers now all we need are some clients that asks varnish for stuff and tests its behaviour.

Say that we have a backend named `SuperBackend` in our vcl file and some logic that states that if your client's request's http.host == `superbackend.tv4.se` one should be passed through to the superbackend.
This behaviour we can now test:

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

I find this pretty selfexplanatory but here goes, we mock a client_testcase and define a request to transmit (`txreq`).
While creating the request we modify the header to have the given host. We then grab the respons and expect it to have status 200 and the backendname as a body.

now we are ready to go, this was a short demonstartion of what you CAN do. But there is more to Urushiol than this. Play around and look at the code.

The whole test would look something like this:

```ruby
require './lib/varnishtest_base'

testcase = Urushiol::VarnishTestBase.new("vcl test")

vcl_file_path = '../new.vcl'

modified_vcl_file = testcase.mock_backends( vcl_file_path )

testcase.mock_varnish "v1" do |varnish|
  varnish.vcl modified_vcl_file
end

testcase.client_testcase "c1" do |test|
  test.txreq do |req|
    req.host "superbackend.tv4.se"
  end
  test.rxresp
  test.expect "resp.status == 200"
  test.expect "resp.body == SuperBackend"
end

testcase.run
```






