module Gollum
  class SitePage < Gollum::Page
    attr_writer :preview
    attr_writer :work_tree
    attr_writer :layouts

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
      name = cname.gsub(/.html$/, '')
      if @preview
        # Find page in work tree
        @work_tree.grep(Regexp.new(name)).each do |path|
          filename = ::File.basename(path)
          if @wiki.page_class.valid_page_name?(filename)
            page = @wiki.page_class.new(@wiki)
            blob = OpenStruct.new(:name => filename, :data => IO.read(path))
            page.populate(blob, filename)
            page.version = @wiki.repo.commit("HEAD")
            return page
          end
        end
      else
        map = @wiki.tree_map_for(version)
        if page = find_page_in_tree(map, name)
          page.version = Grit::Commit.create(@wiki.repo, :id => version)
          page
        end
      end
    end

    # Return layout or nil
    def layout()
      name = '_Layout.html'
      dirs = self.path.split('/')
      dirs.pop
      while !dirs.empty?
        path = dirs.join('/') + '/' + name
        if l = @layouts[path]
          return l
        end
        dirs.pop
      end

      if l = @layouts[name]
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
