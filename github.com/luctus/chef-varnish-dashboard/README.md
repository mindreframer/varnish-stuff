chef-varnish-dashboard
======================

A chef recipe for the amazing Varnish Agent Dashboard (A real time Varnish Cache metrics dashboard).

Requirements
------------

You just need to add the ```varnish``` recipe (https://github.com/opscode-cookbooks/varnish)
and make sure you will install varnish 3.0 or higher by updating the attributes.rb file:

```ruby 
#default['varnish']['version'] = "2.1"
default['varnish']['version'] = "3.0"
```

What does this recipe do?
-------------------------

1) Install automatically the Varnish Agent 2 (*), a small daemon meant to communicate with 
Varnish and other varnish-related services to allow remote control and monitoring of Varnish

2) Clone the Varnish Dashboard project (from @pbruna) (**)

3) Execute the Varnish Agent pointing to the Dashboard project.

(*): https://github.com/varnish/vagent2
(**): https://github.com/pbruna/Varnish-Agent-Dashboard


How to use it?
--------------

- Add the ```varnish``` recipe
- Update the varnish version to 3.0 or higher
- Add this recipe ```chef-varnish-dashboard```
- Go to http://yourproject.com:6085/html/
- It will ask you for a user/pass, enter the one you defined at the ```attributes/default.rb``` file
- Voila!

Tested in:
----------

- Ubuntu (precise 64)
- Let me know if you try this recipe in another OS!

Need help?
----------

You can contact me on twitter: @theluctus
