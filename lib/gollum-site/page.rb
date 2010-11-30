module Gollum
  class SitePage < Gollum::Page
  #class Page
    # Add ".html" extension to page links
    def self.cname(name)
      cname = name.respond_to?(:gsub)      ?
      name.gsub(%r{[ /<>]}, '-') :
        ''

      # account for anchor links (e.g. Page#anchor)
      if pos = cname.index('#')
        cname[0..(pos-1)] + '.html' + cname[pos..-1]
      else
        cname + '.html'
      end
    end

    def find(cname, version)
      name = cname.gsub(/.html$/, '')
      map = @wiki.tree_map_for(version)
      if page = find_page_in_tree(map, name)
        page.version = Grit::Commit.create(@wiki.repo, :id => version)
        page
      end
    end
  end
end
