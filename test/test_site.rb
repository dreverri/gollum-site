require File.join(File.dirname(__FILE__), *%w[helper])

context "Site" do
  setup do
    path = testpath("examples/test_site.git")
    @site = Gollum::Site.new(path,{
                               :output_path => testpath("examples/site"),
                               :version => "master"
                             })
    @site.generate()
  end

  test "generate static site" do
    diff = Dir[@site.output_path + "/**/*"].
      map { |f| f.sub(@site.output_path, "") } - ["/Home.html",
                                                  "/Page-One.html",
                                                  "/Page1.html",
                                                  "/Page2.html",
                                                  "/page.html",
                                                  "/static",
                                                  "/static/static.jpg",
                                                  "/static/static.txt"]
    assert_equal([], diff)
  end

  test "render page with layout and link" do
    home_path = File.join(@site.output_path, "Home.html")
    assert_equal(["<html><p>Site test\n",
                  "<a class=\"internal present\" href=\"/Page1.html#test\">Page1#test</a>\n",
                  "<a class=\"internal present\" href=\"/Page-One.html#test\">Page with anchor</a></p></html>\n"],
                 File.open(home_path).readlines)
  end

  test "render page with layout from parent dir" do
    page_path = File.join(@site.output_path, "Page1.html")
    assert_equal(["<html><p>Site test</p></html>\n"], File.open(page_path).readlines)
  end

  test "render page with layout from sub dir" do
    page_path = File.join(@site.output_path, "Page2.html")
    assert_equal(["<html><body><p>Site test</p></body></html>\n"], File.open(page_path).readlines)
  end

  test "page.path is available on template" do
    page_path = File.join(@site.output_path, "page.html")
    assert_equal(["<ul><li>page.html</li></ul>\n"], File.open(page_path).readlines)
  end

  teardown do
    FileUtils.rm_r(@site.output_path)
  end
end

context "Hooks" do
  setup do
    @path = testpath("examples/test_hooks")
    @repo = Grit::Repo.init(@path)
    @repo.add("#{@path}/_hooks")
    @repo.commit_all("Initial commit")
    @site = Gollum::Site.new(@path, {
                               :output_path => testpath("examples/test_hooks/_site"),
                               :version => :working
                             })
    @site.generate
  end

  test "the before_generate hook is run and the file is written (from inside the hook)" do
    assert File.file?("#{@path}/hello.md")
  end

  test "the before_generate hook is run and the file is written (from inside the hook)" do
    assert File.file?("#{@site.output_path}/hello.html")
  end

  teardown do
    [@site.output_path, "#{@path}/.git", "#{@path}/hello.md"].each do |dir|
      FileUtils.rm_r(dir)
    end
  end
end

context "Preview" do
  setup do
    @path = testpath("examples/uncommitted_untracked_changes")
    @repo = Grit::Repo.init(@path)
    @repo.add("#{@path}")
    @repo.commit_all("Initial commit")
    # Add untracked file
    File.open(@path + '/Foo.md', 'w') { |f| f.write("Bar") }
    # Modify tracked file
    File.open(@path + '/Home.md', 'w') { |f| f.write("Hello World\nHello World") }
    @site = Gollum::Site.new(@path, {
                               :output_path => testpath("examples/site"),
                               :version => :working
                             })
    @site.generate()
  end

  test "working site has Home.html and Foo.html" do
    diff = Dir[@site.output_path + "/**/*"].
      map { |f| f.sub(@site.output_path, "") } - ["/Home.html",
                                                  "/Foo.html",
                                                  "/Bar.html"]
    assert_equal([], diff)
  end

  test "working site Home.html content is uncommitted version" do
    data = IO.read(::File.join(@site.output_path, "Home.html"))
    assert_equal("<p>Hello World\nHello World</p>", data)
  end

  teardown do
    # Remove untracked file
    FileUtils.rm(@path + '/Foo.md')
    # Reset tracked file
    File.open(@path + '/Home.md', 'w') { |f| f.write("Hello World\n") }
    FileUtils.rm_r(@site.output_path)
    FileUtils.rm_r(@path + '/.git')
  end
end

context "Sanitization" do
  setup do
    @path = Dir.mktmpdir('gollumsite')
    @repo = Grit::Repo.init(@path)
    @repo.add("#{@path}")
    @repo.commit_all("Initial commit")
    # protocols
    File.open(@path + '/Home.md', 'w') { |f| f.write("<a href=\"irc://irc.freenode.net/foo\">Hello World</a>") }
    # elements
    File.open(@path + '/Foo.md', 'w') { |f| f.write("<embed src=\"foo.html\">") }
    @site = Gollum::Site.new(@path, {
                               :output_path => testpath("examples/site"),
                               :version => :working,
                               :allow_protocols => ['irc'],
                               :allow_elements => ['embed'],
                               :allow_attributes => ['src']
                             })
    @site.generate()
  end

  test "link with irc protocol" do
    data = IO.read(::File.join(@site.output_path, "Home.html"))
    assert_equal("<p><a href=\"irc://irc.freenode.net/foo\">Hello World</a></p>", data)
  end

  test "embed with src" do
    data = IO.read(::File.join(@site.output_path, "Foo.html"))
    assert_equal("<p><embed src=\"foo.html\"></embed></p>", data)
  end

  teardown do
    FileUtils.rm_r(@site.output_path)
    FileUtils.rm_r(@path)
  end

end
