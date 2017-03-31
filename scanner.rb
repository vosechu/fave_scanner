require "rubygems"
require "mechanize"
require "contracts"

class Scanner
  include Contracts::Core
  include Contracts::Builtin

  FILE_PATH = "/tmp/fave_scanner"

  attr_reader :agent

  Contract nil => Scanner
  def initialize
    @agent = Mechanize.new
    @agent.pluggable_parser.default = Mechanize::Download


    return self
  end

  Contract nil => Scanner
  def scan
    image_statuses = []
    next_url = 'http://mlkshk.com/user/vosechu/likes'
    # next_url = 'http://mlkshk.com/user/vosechu/likes/before/6101651'

    puts "starting with: #{next_url}"

    while(next_url) do
      page = Page.new(agent, next_url)

      next_url = page.older_url
      image_statuses += page.download_images

      print "sleeping: "

      10.times do
        sleep 1
        print "."
      end

      puts ""
      puts ""
      puts "next page: http://mlkshk.com#{next_url}"
    end

    return self
  end
end

class Page
  include Contracts::Core
  include Contracts::Builtin

  attr_reader :agent, :page

  Contract Mechanize, String => Page
  def initialize(agent, next_url)
    @agent = agent
    @page = agent.get(next_url)

    return self
  end

  Contract nil => String
  def older_url
    page.link_with(text: "« Older").attributes["href"]
  end

  Contract nil => ArrayOf[Hash]
  def images_with_metadata
    images = []

    image_headers.each_with_index do |header, index|
      images << {
        title: header[:title],
        original_poster: header[:original_poster],
        url: image_urls[index]
      }
    end

    return images
  end

  Contract nil => ArrayOf[String]
  def download_images
    file_paths = []

    print "downloading: "

    images_with_metadata.each do |image|
      next if image[:url].empty?

      begin
        image_file = agent.get(image[:url])
      rescue ResponseCodeError => e
        $stderr.puts "Failed to download an image: #{e}"
      end

      extension = nil
      case image_file.response["content-type"]
      when "image/jpeg", "image/jpg"
        extension = "jpg"
      when "image/gif"
        extension = "gif"
      when "image/png"
        extension = "png"
      else
        raise "unknown mime-type #{image_file.response["content-type"]}"
      end

      image_file.save!(File.join(Scanner::FILE_PATH, "#{image[:original_poster]}---#{File.basename(image[:url])}---#{sanitize_filename(image[:title])}.#{extension}"))

      sleep 1
      print "."
    end

    puts ""

    return file_paths
  end

  private

  Contract nil => ArrayOf[{ title: String, original_poster: String }]
  def image_headers
    @page.search(".image-title").map do |link|
      {
        title: link.search("h3").text,
        original_poster: link.search(".image-poster a").attribute("title").value
      }
    end
  end

  Contract nil => ArrayOf[String]
  def image_urls
    @image_urls ||= begin
      @page.search(".image-content .the-image").map do |link|
        link.search("a img").attribute("src").value rescue ""
      end
    end
  end

  # http://stackoverflow.com/a/10823131/203731
  Contract String => String
  def sanitize_filename(filename)
    # Split the name when finding a period which is preceded by some
    # character, and is followed by some character other than a period,
    # if there is no following period that is followed by something
    # other than a period (yeah, confusing, I know)
    fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

    # We now have one or two parts (depending on whether we could find
    # a suitable period). For each of these parts, replace any unwanted
    # sequence of characters with an underscore
    fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

    # Finally, join the parts with a period and return the result
    return fn.join '.'
  end
end

if __FILE__ == $0
  Scanner.new.scan
end
