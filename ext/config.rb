# Example regex file, expressions order matters !
@regexs = {
  /^(images)\/.*_(\d+)\.(png)$/ => [1,3,2]
  /^\/(\w+)\/.*\.(\w+)$/ => [1, 2],
}

# will match URLs and display them such as:
#
# /images/11/22/logo_400.png   => images:png:400
#
# first, then:
#
# /assets/your/own/path/app.js => assets:js
#
# /images/00/11/banner.jpg     => images:jpg
#
# validate these expressions using the fine http://rubular.com/
