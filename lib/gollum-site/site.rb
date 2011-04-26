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
                                 :markup_class => Gollum::SiteMarkup,
                                 :page_class => Gollum::SitePage,
                                 :base_path => options[:base_path],
                                 :sanitization => Gollum::SiteSanitization.new,
                                 :history_sanitization => Gollum::SiteSanitization.new
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

      @commit = @version == :working ? @wiki.repo.commit("HEAD") : @wiki.repo.commit(@version)
      items = self.ls(@version)

      items.each do |item|
        filename = ::File.basename(item.path)
        dirname = ::File.dirname(item.path)
        if filename =~ /^_Footer./
          # ignore
        elsif filename =~ /^_Layout.html/
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
        ls_opts = {
          :others => true,
          :exclude_standard => true,
          :cached => true,
          :z => true
        }

        ls_opts_del = {
          :deleted => true,
          :exclude_standard => true,
          :z => true
        }

        # if output_path is in work_tree, it should be excluded
        if ::File.expand_path(@output_path).match(::File.expand_path(@wiki.repo.git.work_tree))
          ls_opts[:exclude] = @output_path
          ls_opts_del[:exclude] = @output_path
        end

        cwd = Dir.pwd # need to change directories for git ls-files -o
        Dir.chdir(@wiki.repo.git.work_tree)
        deleted = @wiki.repo.git.native(:ls_files, ls_opts_del).split("\0")
        working = @wiki.repo.git.native(:ls_files, ls_opts).split("\0")
        work_tree = (working - deleted).map do |path|
          path = decode_git_path(path)
          OpenStruct.new(:path => path, :data => IO.read(path))
        end
        Dir.chdir(cwd) # change back to original directory
        return work_tree
      else
        return @wiki.tree_map_for(version).map do |entry|
          OpenStruct.new(:path => entry.path, :data => entry.blob(@wiki.repo).data)
        end
      end
    end

    # path must be relative to top level of wiki repo
    def update_working_item(path)
      filename = ::File.basename(path)
      dirname = ::File.dirname(path)
      if filename =~ /^_Footer./
        # ignore
      elsif filename =~ /^_Layout.html/
        # layout
      elsif @wiki.page_class.valid_page_name?(filename)
        # page
        abspath = ::File.join(@wiki.repo.git.work_tree, path)
        page = @wiki.page_class.new(@wiki)
        blob = OpenStruct.new(:name => filename, :data => IO.read(abspath))
        page.populate(blob, dirname)
        page.version = @commit
        @pages[page.name.downcase] = page
        page.generate(@output_path, @version)
      else
        # file
        data = IO.read(abspath)
        @files[path] = data
        path = ::File.join(@output_path, path)
        ::FileUtils.mkdir_p(::File.dirname(path))
        ::File.open(path, "w") do |f|
          f.write(data)
        end
      end
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
  end
end
