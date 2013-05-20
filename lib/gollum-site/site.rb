module Gollum

  class Site
    def self.default_layout_dir()
      ::File.join(::File.dirname(::File.expand_path(__FILE__)), "layout")
    end

    attr_reader :output_path
    attr_reader :layouts
    attr_reader :pages

    def initialize(path, options = {})
      @wiki = Gollum::Wiki.new(path, {
                                 :markup_classes => Hash.new(Gollum::SiteMarkup),
                                 :page_class => Gollum::SitePage,
                                 :base_path => options[:base_path] || '/',
                                 :sanitization => sanitization(options),
                                 :history_sanitization => sanitization(options)
                               })
      @wiki.site = self
      @output_path = options[:output_path] || "_site"
      @version = options[:version] || "master"
    end

    # Prepare site for specified version
    def prepare()
      @pages = {}
      @files = {}
      @layouts = {}

      @commit = @version == :working ? @wiki.repo.head.commit : @wiki.repo.commit(@version)
      items = self.ls(@version)

      items.each do |item|
        filename = ::File.basename(item.path)
        dirname = ::File.dirname(item.path)
        if filename =~ /^_Layout.html/
          # layout
          @layouts[item.path] = ::Liquid::Template.parse(item.data)
        elsif @wiki.page_class.valid_page_name?(filename)
          # page
          page = @wiki.page_class.new(@wiki)
          blob = OpenStruct.new(:name => filename, :data => item.data)
          page.populate(blob, dirname)
          page.version = @commit
          @pages[page.name.downcase] = page
        else
          # file
          @files[item.path] = item.data
        end
      end
    end

    def ls(version = 'master')
      if version == :working
        return in_work_tree do
          working = ls_files(:exclude => @output_path, :others => true, :cached => true)
          deleted = ls_files(:exclude => @output_path, :deleted => true)
          ignored = ignored_list(version)
          valid_files = working - deleted - ignored
          valid_files.map do |path|
            OpenStruct.new(:path => path, :data => IO.read(path))
          end
        end
      else
        return @wiki.tree_map_for(version).reject {|entry| ignored? entry.path }.map do |entry|
          OpenStruct.new(:path => entry.path, :data => entry.blob(@wiki.repo).data)
        end
      end
    end

    def sanitization(options)
      site_sanitization = Gollum::SiteSanitization.new
      site_sanitization.elements.concat options[:allow_elements] || []
      site_sanitization.attributes[:all].concat options[:allow_attributes] || []
      site_sanitization.protocols['a']['href'].concat options[:allow_protocols] || []
      site_sanitization
    end

    # Public: generate the static site
    def generate()
      prepare
      ::Dir.mkdir(@output_path) unless ::File.exists? @output_path

      @pages.each do |name, page|
        SiteLog.debug("Starting page generation - #{name}")
        page.generate(@output_path, @version)
        SiteLog.debug("Finished page generation - #{name}")
      end

      @files.each do |path, data|
        path = ::File.join(@output_path, path)
        ::FileUtils.mkdir_p(::File.dirname(path))
        ::File.open(path, "w") do |f|
          f.write(data)
        end
      end
    end

    def to_liquid
      { "pages" => @pages }
    end

    # Decode octal sequences (\NNN) in tree path names.
    #
    # path - String path name.
    #
    # Returns a decoded String.
    def decode_git_path(path)
      if path[0] == ?" && path[-1] == ?"
        path = path[1...-1]
        path.gsub!(/\\\d{3}/)   { |m| m[1..-1].to_i(8).chr }
      end
      path.gsub!(/\\[rn"\\]/) { |m| eval(%("#{m.to_s}")) }
      path
    end

    def ignored?(path)
      @ignored_list ||= ignored_list
      @ignored_list.include? path
    end

    def ignored_list(version = 'master')
      in_work_tree do
        ignore = ls_files(:ignored => true, :exclude_from => '.gollumignore')
        if version == :working
          ignore += ls_files(:ignored => true, :exclude_from => '.gollumignore', :other => true)
        else
          ignore += ls_files(:other => true)
        end
        # grit does not correctly handle multiple options with the same name
        ignore += ls_files(:ignored => true, :exclude => '.gollumignore')
        ignore += ls_files(:ignored => true, :exclude => '.gitignore')
        ignore += ls_files(:ignored => true, :exclude => '_Sidebar.*')
        ignore += ls_files(:ignored => true, :exclude => '_Footer.*')
      end
    end

    def ls_files(opts)
      opts.merge!(:z => true, :exclude_standard => true)
      @wiki.repo.git.native(:ls_files, opts).split("\0").map {|path| decode_git_path(path) }
    end

    def in_work_tree
      cwd = Dir.pwd
      Dir.chdir(@wiki.repo.git.work_tree)
      result = yield
      Dir.chdir(cwd)
      result
    end
  end # Site

end # Gollum
