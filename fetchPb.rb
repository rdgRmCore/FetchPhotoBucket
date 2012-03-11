require 'rubygems'
require 'mechanize'
require 'ap'

startPage = "StartPage.html"
imgPage = "ImgPage.html"

albumFile = File.new("AlbumUrl.txt", "r")
startUrl  = albumFile.gets
puts "Album url is: #{startUrl}"

def getHtmlPage(page, url)
  if !File.exist? page then
    puts  "Need to go get " + page + "."
    agent = Mechanize.new
    dlPage = agent.get(url)
    dlPage.save(page);
  end
end

def openPage(page, url)
  getHtmlPage(page, url)
  puts  "Read " + page + " from local disk."
  doc = Nokogiri::HTML(open(page))
  return doc
end

def getLink(doc)
  thumbs = doc.css('div.thumbnail').collect
  firstThumb = thumbs.peek
  theLink = firstThumb.css('a').map {|link| link['href']}
  ap theLink
  return theLink[0]
end

$dupDirNum = 0
def processImgPage(doc)
  desc = doc.css('span.desc')
  puts desc

  title = doc.css('title')
  stripTitle = title.text.partition(" picture")[0]

  dirName = stripTitle.gsub(/ /, '-')
  dirName = dirName.gsub(/\//, '-')
  puts dirName
  if !File.exist? dirName then
    puts "Creating directory" + dirName
    Dir.mkdir(dirName)
    $dupDirNum = 0
  else 
    $dupDirNum = $dupDirNum + 1
    dirName += $dupDirNum.to_s
    puts "Creating directory" + dirName
    Dir.mkdir(dirName)
    
  end

  imgSrc = doc.search("//img[@id = 'fullImage']/@src")

  imgName = File.basename(imgSrc.to_s)

  fullImgName = dirName + "/" + imgName
  puts fullImgName

  if !File.exist? fullImgName then
    puts "Downloading file" + imgSrc.to_s
    agent = Mechanize.new
    agent.pluggable_parser.default = Mechanize::Download
    agent.get(imgSrc).save(fullImgName)
  end

  page = "<html>\n<head>\n <title>"
  page += stripTitle
  page += "</title>\n"
  page += "</head>\n\n"
  page += "<body>\n"
  page += "<img src=\""
  page += imgName
  page += "\" alt=\""
  page += stripTitle
  page += "\" />"
  page += "<h2>\n"
  page += stripTitle
  page += "</h2>\n"
  page += "<p>\n"
  page += desc.text
  page += "</p>\n"
  page += "</body>\n"
  page += "</html>\n"

  fullPageName = dirName + "/" + dirName + ".html"
  
  if !File.exist? fullPageName then
    puts "Writing out file" + fullPageName
    outHtmlFile = File.new(fullPageName, "w")
    outHtmlFile.write(page)
    outHtmlFile.close
  end

end

doc  = openPage(startPage, startUrl)

thumbs = doc.css('div.thumbnail').collect
i = 1
thumbs.each do |thumb| 
  theLink = thumb.css('a').map {|link| link['href']}
  puts "processing the image..."
  ap theLink
  imgPageName = "img" + i.to_s + ".html"
  i += 1

  if theLink.empty? then 
    puts "\nThe link is empty. Skipping " + imgPageName + "\n"
  else
    imgDoc = openPage(imgPageName, theLink[0])
    processImgPage(imgDoc)
    sleep(2)
  end
end
