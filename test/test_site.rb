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
    home_path_file = File.open(home_path)
    assert_equal("<html><p>Site test\n", home_path_file.readline)
    assert_equal("<a class=\"internal present\" href=\"/Page1.html#test\">Page1#test</a>\n", home_path_file.readline)
    assert_match(/<a class="internal present" href="\/Page-One.html#test">Page with anchor<\/a><\/p>/, home_path_file.readline)
  end

  test "render page with layout from parent dir" do
    page_path = File.join(@site.output_path, "Page1.html")
    assert_match(/<html><p>Site test<\/p>.*\n/, File.open(page_path).readline)
  end

  test "render page with layout from sub dir" do
    page_path = File.join(@site.output_path, "Page2.html")
    assert_match(/<html><body><p>Site test<\/p>.*\n/, File.open(page_path).readline)
  end

  test "page.path is available on template" do
    page_path = File.join(@site.output_path, "page.html")
    assert_equal(["<ul><li>page.html</li></ul>\n"], File.open(page_path).readlines)
  end

  teardown do
    FileUtils.rm_r(@site.output_path)
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
    assert_match(/<p>Hello World\nHello World<\/p>/, data)
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

context "Ignorefile" do
  setup do
    @path = testpath("examples/test_ignorefile.git")
    @repo = Grit::Repo.init(@path)
    File.open(@path + '/.gollumignore', 'w') { |f| f.write("Ignore*.*") }
    File.open(@path + '/Home.md', 'w') { |f| f.write("Home file.") }
    File.open(@path + '/IgnoreRepo.md', 'w') { |f| f.write("Ignore this repo file.") }
    @repo.add(@path)
    @repo.commit_all("Initial commit.")
    # Add untracked working files
    File.open(@path + '/IgnoreWorking.md', 'w') { |f| f.write("Ignore this working file.") }
    File.open(@path + '/UseWorking.md', 'w') { |f| f.write("Use me.") }
    @site = Gollum::Site.new(@path, {
                               :output_path => testpath("examples/site"),
                               :version => :working
                             })
    @site.generate()
  end

  test "working site has no ignored files" do
    diff = Dir[@site.output_path + "/**/*"].
      map { |f| f.sub(@site.output_path, "") }
    assert_equal(["/Home.html", "/UseWorking.html"], diff)
  end

  teardown do
    FileUtils.rm_r(@site.output_path)
    FileUtils.rm_r(@path)
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
    assert_match(/<p><a href="irc:\/\/irc.freenode.net\/foo">Hello World<\/a><\/p>/, data)
  end

  test "embed with src" do
    data = IO.read(::File.join(@site.output_path, "Foo.html"))
    assert_match(/<p><embed src="foo.html"><\/embed><\/p>/, data)
  end

  teardown do
    FileUtils.rm_r(@site.output_path)
    FileUtils.rm_r(@path)
  end

end

context "Sidebar and Footer" do
  setup do
    @path = testpath("examples/test_footer_and_sidebar.git")

    @site = Gollum::Site.new(@path, {
                               :output_path => testpath("examples/site"),
                               :version => "master"
                             })
    @site.generate()
  end

  test "Sidebar and Footer files are ignored" do
    assert !File.exists?(@site.output_path + '_Footer.html')
    assert !File.exists?(@site.output_path + '_Sidebar.html')
  end

  test "Footer is rendered in _Layout" do
    data = IO.read(::File.join(@site.output_path, "footer.html"))
    assert_match /<p>hello<\/p>\n/, data
  end

  test "Sidebar is rendered in _Layout" do
    data = IO.read(::File.join(@site.output_path, "sidebar.html"))
    assert_match /<p>world<\/p>\n/, data
  end

  teardown do
    FileUtils.rm_r(@site.output_path)
  end
end
