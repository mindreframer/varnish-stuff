import cherrypy
from cherrypy.lib.httputil import HTTPDate

class CacheTest(object):
    def default(self, *args, **kwargs):
        import datetime, time
        from email import utils
        nowdt = datetime.datetime.now()
        nowishdt = nowdt.replace(second=0, microsecond=0)
        nowtuple = nowishdt.timetuple()
        nowtimestamp = time.mktime(nowtuple)
        fmtstr = utils.formatdate(nowtimestamp)
        
        print repr(cherrypy.request.headers.get('If-Modified-Since'))

        cherrypy.response.headers['Last-Modified'] = fmtstr
        #cherrypy.response.headers['Cache-Control'] = 'max-age=7200, must-revalidate'
        #cherrypy.response.headers['Cache-Control'] = 'max-age=7200, no-cache, must-revalidate'
        cherrypy.log('Dealing with request...')
        cherrypy.log(str(cherrypy.request.headers))
        cherrypy.lib.cptools.validate_since()
        cherrypy.log('... with a 200.')
        return "Generated for %s at %s\n" % (nowishdt, nowdt)
    default.exposed = True

cherrypy.quickstart(CacheTest())
