module Gollum
  class Page
    # Add ".html" extension to page links
    def self.cname(name)
      cname = name.respond_to?(:gsub)      ?
      name.gsub(%r{[ /<>]}, '-') :
        ''
      cname + '.html'
    end

    def find(cname, version)
      name = cname[0..-6]
      if commit = @wiki.repo.commit(version)
        if page = find_page_in_tree(commit.tree, name)
          page.version = commit
          page
        end
      end
    end
  end
end
