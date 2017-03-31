require "rubygems"
require "mechanize"
require "contracts"

class Scanner
  include Contracts::Core
  include Contracts::Builtin

  attr_reader :agent

  Contract nil => Scanner
  def initialize
    @agent = Mechanize.new

    return self
  end

  Contract nil => Scanner
  def scan
    image_urls = []
    next_url = 'http://mlkshk.com/user/vosechu/likes'
    while(next_url) do
      page = Page.new(agent, next_url)

      next_url = page.older_url
      image_urls += page.image_urls

      puts next_url
      puts image_urls

      10.times do
        sleep 1
        print "."
      end
      puts ""
    end

    return self
  end
end

class Page
  include Contracts::Core
  include Contracts::Builtin

  attr_reader :page

  Contract Mechanize, String => Page
  def initialize(agent, next_url)
    @page = agent.get(next_url)

    return self
  end

  Contract nil => String
  def older_url
    page.link_with(text: "« Older").attributes["href"]
  end

  Contract nil => ArrayOf[String]
  def image_urls
    @page.search(".image-content .the-image a img").map do |link|
      link.attributes["src"].value
    end
  end
end

if __FILE__ == $0
  Scanner.new.scan
end
