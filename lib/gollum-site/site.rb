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
          # Output page html
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
