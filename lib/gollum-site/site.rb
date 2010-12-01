module Gollum
  class Site
    def self.default_layout_dir()
      ::File.join(::File.dirname(::File.expand_path(__FILE__)), "layout")
    end

    attr_reader :output_path

    def initialize(path, options = {})
      @wiki = Gollum::Wiki.new(path, {
                                 # markup_class should work after v1.1.0 of Gollum
                                 # need to change class name in markup.rb
                                 #:markup_class => Gollum::SiteMarkup,
                                :page_class => Gollum::SitePage,
                                :base_path => options[:base_path]})
      @output_path = options[:output_path] || "_site"
    end

    # Generate static HTML including uncommitted/untracked changes
    def preview()
      if @wiki.repo.git.work_tree == @wiki.repo.git.git_dir
        raise Exception("This operation must be run in a work tree")
      end
      ::Dir.mkdir(@output_path) unless ::File.exists? @output_path

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
        @wiki.decode_git_path(path)
      end
      Dir.chdir(cwd) # change back to original directory

      layouts = {}
      work_tree.each do |path|
        filename = ::File.basename(path)
        if filename =~ /^_Layout.html/
          abspath = ::File.join(@wiki.repo.git.work_tree, path)
          layouts[path] = ::Liquid::Template.parse(IO.read(abspath))
        end
      end

      work_tree.each do |path|
        abspath = ::File.join(@wiki.repo.git.work_tree, path)
        filename = ::File.basename(path)
        if filename =~ /(^_Footer.|^_Layout.html)/
          # Ignore
        elsif @wiki.page_class.valid_page_name?(filename)
          # Output page HTML
          page = @wiki.page_class.new(@wiki)
          blob = OpenStruct.new(:name => filename, :data => IO.read(abspath))
          page.populate(blob, ::File.dirname(path))
          page.version = @wiki.repo.commit("HEAD")
          page.preview = true
          page.work_tree = work_tree
          page.layouts = layouts
          page.generate(@output_path, "HEAD")
        else
          opath = ::File.join(@output_path, path)
          ::FileUtils.mkdir_p(::File.dirname(opath))
          data = IO.read(abspath)
          f = ::File.new(opath, "w")
          f.write(data)
          f.close
        end
      end
    end

    # Public: generate a static site
    #
    # version - The String version ID to generate (default: "master").
    #
    def generate(version = 'master')
      ::Dir.mkdir(@output_path) unless ::File.exists? @output_path

      items = @wiki.tree_map_for(version).each do |entry|
        if entry.name =~ /(^_Footer.|^_Layout.html)/
          # Ignore
        elsif @wiki.page_class.valid_page_name?(entry.name)
          # Output page HTML
          sha = @wiki.ref_map[version] || version
          entry.page(@wiki, @wiki.repo.commit(sha)).generate(@output_path, version)
        else
          # Write file to output_path
          path = ::File.join(@output_path, entry.path)
          ::FileUtils.mkdir_p(::File.dirname(path))
          data = entry.blob(@wiki.repo).data
          f = ::File.new(path, "w")
          f.write(data)
          f.close
        end
      end
    end
  end
end
