module Gollum
  class Page
    # Add ".html" extension to page links
    def self.cname(name)
      cname = name.respond_to?(:gsub)      ?
        name.gsub(%r{[ /<>]}, '-') :
        ''
      cname + '.html'
    end
  end
end
