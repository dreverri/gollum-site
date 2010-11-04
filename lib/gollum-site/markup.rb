require 'digest/sha1'
require 'cgi'

module Gollum
  class Markup
    # Find a page from a given cname.  If the page has an anchor (#) and has
    # no match, strip the anchor and try again.
    #
    # cname - The String canonical page name.
    #
    # Returns a Gollum::Page instance if a page is found, or an Array of 
    # [Gollum::Page, String extra] if a page without the extra anchor data
    # is found.
    def find_page_from_name(cname)
      if page = @wiki.page(cname, @version)
        return page
      end
      if pos = cname.index('#')
        [@wiki.page(cname[0...pos], @version), cname[pos..-1]]
      end
    end
  end
end
