require 'gollum'
require 'liquid'
require 'gollum-site/site'

# Use custom Page class to overwrite cname and find method
require 'gollum-site/page'

# Markup does not use page version :(
# Markup does not handle anchor tags for absent pages
# Use custom Markup class once Gollum supports it (>v1.1.0)
require 'gollum-site/markup'
