::File.open("#{@path}/hello.md", "w") do |file|
  file << "Sample generated content"
end