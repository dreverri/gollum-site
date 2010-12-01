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

context "Preview" do
  setup do
    @path = testpath("examples/uncommitted_untracked_changes")
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

  test "one item can be updated" do
    File.open(@path + '/Foo.md', 'w') { |f| f.write("Baz") }
    @site.update_working_item('Foo.md')
    data = IO.read(::File.join(@site.output_path, "Foo.html"))
    assert_equal("<p>Baz</p>", data)
  end

  teardown do
    # Remove untracked file
    FileUtils.rm(@path + '/Foo.md')
    # Reset tracked file
    File.open(@path + '/Home.md', 'w') { |f| f.write("Hello World\n") }
    FileUtils.rm_r(@site.output_path)
  end
end
