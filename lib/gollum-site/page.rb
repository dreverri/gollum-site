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
      @wiki.site.pages[name.downcase]
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
               SiteLog.debug("Found layout - #{name}")
               SiteLog.debug("Starting page rendering - #{name}")
               rendered = l.render( 'page' => self,
                         'site' => @wiki.site,
                         'wiki' => {'base_path' => @wiki.base_path})
               SiteLog.debug("Finished page rendering - #{name}")
               rendered
             else
               SiteLog.debug("Did not find layout - #{name}")
               formatted_data
             end

      ::File.open(::File.join(output_path, self.class.cname(name)), 'w') do |f|
        f.write(data)
      end
    end

    # Return data for Liquid template
    def to_liquid
      @to_liquid ||= liquify
    end

    def liquify
      SiteLog.debug("Starting page liquefication - #{name}")
      data = {
        "path" => self.class.cname(name),
        "link" => ::File.join(@wiki.base_path, CGI.escape(self.class.cname(name))),
        "content" => formatted_data,
        "title" => title,
        "format" => format.to_s
      }
      data["author"] = version.author.name rescue nil
      data["date"] = version.authored_date.strftime("%Y-%m-%d %H:%M:%S") rescue nil
      data["footer"] = footer.formatted_data if footer
      data["sidebar"] = sidebar.formatted_data if sidebar
      SiteLog.debug("Finished page liquefication - #{name}")
      return data
    end

    def populate(blob, path)
      @blob = blob
      @path = (path + '/' + blob.name)
      self
    end

    def formatted_data(&block)
      if @formatted_data.nil?
        SiteLog.debug("Starting page formatting - #{name}")
        @formatted_data = super(&block)
        SiteLog.debug("Finished page formatting - #{name}")
      end
      return @formatted_data
    end
  end
end
