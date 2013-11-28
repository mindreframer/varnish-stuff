#!/usr/bin/env python

#
# Script uses the following flow:
# - Hash existing prerender_backend.vcl file contents
# - Get ip addresses for rendering backend
# - Make sure that there was at least one ip address returned
# - Build backend node array
# - Add backend node array to director
# - Hash generated director
# - If hashes differ:
#     - Update prerender_backend.vcl
#     - Reload Varnish configuration
# - Notify on any errors
#
# TODO: Add logging
# TODO: Add notifications
# TODO: Add error checking
# TODO: Add Varnish reloading
#

import hashlib
import optparse
import socket

desc = """Generate a Varnish backend configuration given a hostname."""

parser = optparse.OptionParser(description=desc)
parser.add_option('-n', '--hostname',
                  dest='hostname',
                  help='prerender.io rendering backend hostname',
                  default='prerender.herokuapp.com')
parser.add_option('-p', '--port',
                  dest='port',
                  help='prerender.io rendering backend port',
                  type='int',
                  default=80)
parser.add_option('-d', '--dest',
                  dest='backend_conf',
                  help='varnish backend conf file to overwrite',
                  default='/etc/varnish/prerender_backend.vcl')
parser.add_option('-q', '--quiet',
                  action='store_true',
                  dest='quiet',
                  help='don\'t display generated conf',
                  default=False)
parser.add_option('--dry-run',
                  action='store_true',
                  dest='dry_run',
                  help='don\'t write to conf file or reload Varnish',
                  default=False)
(opts, args) = parser.parse_args()

TPL_NODE = '''    {
        .backend = {
            .host = "%s";
            .port = "%d";
        }
        .weight = 1;
    }
'''

TPL_DIRECTOR = '''director prerender random {
%s}
'''

# Get ip addresses for rendering backend
(_, _, rawaddrs) = socket.gethostbyname_ex(opts.hostname)
rawaddrs.sort()
addrs = set(rawaddrs)

# Make sure that there was at least one ip address returned
if not addrs:
    1  # FIXME: Send notification and exit

# Build backend node array and director
nodes = ''.join([(TPL_NODE % (addr, opts.port)) for addr in addrs])
director = TPL_DIRECTOR % (nodes)

# Compare generated director to existing director
try:
    filehash = hashlib.sha256(open(opts.backend_conf, 'rb').read()).hexdigest()
except IOError:
    # Assume no file exists and set hash to '' so that it wil be created
    filehash = ''
stringhash = hashlib.sha256(director).hexdigest()

if filehash != stringhash:
    if not opts.dry_run:
        backend_conf = open(opts.backend_conf, 'w')
        backend_conf.write(director)
        backend_conf.close()

        print "Updated backend configuration"
    else:
        print ("Backend configuration in %s differs from generated director" %
               (opts.backend_conf))

    # TODO: Reload Varnish configuration

if not opts.quiet:
    print "Generated Varnish conf:"
    print director


# def main():
#     return
#     # generate_homepages()
#     # copy_to_working_dir()
#     # customize_for_servers()
#     # deploy_to_production()
#     # log_generation()


# if __name__ == '__main__':
#     main()
