require 'gollum'
require 'liquid'
require 'gollum-site/site'

# overwrite cname and find method in Page class
# should replace with custom Page class once issue #63 is fixed
# http://github.com/github/gollum/issues/#issue/63
require 'gollum-site/page'

# Markup does not use page version :(
# Markup does not handle anchor tags for absent pages
require 'gollum-site/markup'
