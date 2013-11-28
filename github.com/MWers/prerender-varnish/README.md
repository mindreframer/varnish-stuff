# prerender-varnish

prerender-varnish is a Varnish configuration for serving pre-rendered HTML from Javascript pages/apps using [prerender.io](http://prerender.io/).

prerender-varnish is currently in a pre-alpha state and is actively being developed. Anything can *and likely will* change.

## Using prerender-varnish

To use prerender-varnish, symlink `prerender.vcl` and `prerender_backend.vcl` in your Varnish configuration directory (usually `/etc/varnish`) and add them to your primary Varnish configuration file:

```c
include "prerender.vcl";
```

## Updating prerender.io backend

The prerender.io rendering service is hosted on Heroku and Heroku (and AWS ELB) domains resolve to multiple IP addresses. Varnish requires backend hosts to resolve to a single IP address. As a workaround, `backend_generator.py` will query DNS for the prerender.io rendering service, generate a Varnish director containing all rendering service IP addresses, write it to `prerender_backend.vcl`, and reload Varnish when the configuration changes.

Run `backend_generator.py` as follows:

```bash
VARNISH_SECRET=xxxxxxx python backend_generator.py [host] [port]
```

With TTLs for these DNS records set quite low, it is advised to run this very frequently. Once per minute should be sufficient.

## License

The MIT License (MIT)

Copyright (c) 2013 Matthew Walker

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
