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

    def find(cname, version)
      name = cname.gsub(/.html$/, '')
      map = @wiki.tree_map_for(version)
      if page = find_page_in_tree(map, name)
        page.version = Grit::Commit.create(@wiki.repo, :id => version)
        page
      end
    end

    # Return layout or nil
    def layout(version)
      dirs = self.path.split('/')
      dirs.pop
      file = @wiki.file_class.new(@wiki)
      while !dirs.empty?
        if f = file.find(dirs.join('/') + '/_Layout.html', version)
          return ::Liquid::Template.parse(f.raw_data)
        end
        dirs.pop
      end

      if f = file.find('_Layout.html', version)
        return ::Liquid::Template.parse(f.raw_data)
      end
    end

    # Output static HTML of current page
    def generate(output_path, version)
      data = if l = layout(version)
        l.render( 'page' => self,
                  'wiki' => {'base_path' => @wiki.base_path})
      else
        formatted_data
      end

      f = ::File.new(::File.join(output_path, self.class.cname(name)), 'w')
      f.write(data)
      f.close
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
  end
end
