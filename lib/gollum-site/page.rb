module Gollum
  class SitePage < Gollum::Page
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

    # Markup uses this method for absent/present class assignment on page links
    def find(cname, version)
      name = self.class.canonicalize_filename(cname)
      @wiki.site.pages[name]
    end

    # Return layout or nil
    def layout()
      name = '_Layout.html'
      dirs = self.path.split('/')
      dirs.pop
      while !dirs.empty?
        path = dirs.join('/') + '/' + name
        if l = @wiki.site.layouts[path]
          return l
        end
        dirs.pop
      end

      if l = @wiki.site.layouts[name]
        return l
      end
    end

    # Output static HTML of current page
    def generate(output_path, version)
      data = if l = layout()
        l.render( 'page' => self,
                  'wiki' => {'base_path' => @wiki.base_path})
      else
        formatted_data
      end

      ::File.open(::File.join(output_path, self.class.cname(name)), 'w') do |f|
        f.write(data)
      end
    end

    # Return data for Liquid template
    def to_liquid()
      { "path" => self.class.cname(name),
        "content" => formatted_data,
        "title" => title,
        "format" => format.to_s,
        "author" => version.author.name,
        "date" => version.authored_date.strftime("%Y-%m-%d %H:%M:%S")}
    end

    def populate(blob, path)
      @blob = blob
      @path = (path + '/' + blob.name)
      self
    end
  end
end
