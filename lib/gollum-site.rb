require 'gollum'
require 'liquid'
require 'gollum-site/site'

# Use custom Page class to overwrite cname and find method
require 'gollum-site/page'

# Markup does not use page version :(
# Markup does not handle anchor tags for absent pages
require 'gollum-site/markup'

# Absolutely awful hack
require 'gollum-site/wiki'

# Logging
require 'mixlib/log'
require 'gollum-site/log'

require 'gollum-site/sanitization'
