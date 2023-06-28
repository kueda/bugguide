#encoding: utf-8
#
# Represents a single photo on BugGuide. Several methods are intended for
# compatability with the DarwinCore SimpleMultimedia extention (http://rs.gbif.org/terms/1.0/Multimedia).
#
class BugGuide::Photo
  attr_accessor :thumbnail_url, :id, :url, :title, :date, :state, :county, :city_location, :taxon

  def initialize(options = {})
    options.each do |k,v|
      send("#{k}=", v)
    end
  end


  # Search for photos. This method depends on BugGuide's Advanced Search
  # functionality, which will bail if your search returns too much results, so
  # this will throw an exception in that case that you should be prepared to
  # deal with.
  #
  # @param options [Hash] You need to choose enough to filter the results adequately
  #  user: user ID
  #  taxon: ancestor taxon ID
  #  description: free text search in the description of the photo
  #  month: numerical month of the year, 1-12
  #  location: two-letter US state or Canadian province code, e.g. AK, BC, WA, OR, 
  #    CA, etc. You can specify multiple states as an array of these codes.
  #  county: County or region name. No controlled voabulary, so you can use "Madera" 
  #    but also "Sierra"
  #  city_location: City or location name. Like county it's free text.
  #  adult: Boolean
  #  immature: Boolean
  #  male: Boolean
  #  female: Boolean
  #  representative: Boolean. It's not clear to me what this means on BugGuide.
  def self.search(options = {})
    raise BugGuide::NoParametersException if options.blank?
    url = "https://bugguide.net/adv_search/bgsearch.php?"
    options.stringify_keys!
    headers = options[:headers] || {}
    params = []
    %w(user taxon description county city_location adult immature male female representative).each do |param|
      next if options[param] != false && options[param].blank?
      params << if options[param] == true || options[param] == false
        "#{param}=#{options[param] ? 1 : 0}"
      else
        "#{param}=#{options[param]}"
      end
    end
    states = [options['state'], options['location']].flatten.compact.uniq
    params << states.map{|s| "location[]=#{s}"} unless states.blank?
    params << [options['month']].flatten.map{|s| "month[]=#{s}"} unless options['month'].blank?
    url += URI::Parser.new.escape( params.join('&') )
    photos = []
    # puts "fetching #{url}"
    open(url, headers) do |response|
      html = Nokogiri::HTML(response.read.encode('UTF-8'))
      if html.to_s =~ /Too many results \(\d+\)/
        raise BugGuide::TooManyResultsException
      end
      html.css('body > table tr').each do |tr|
        next if tr.css('th').size > 0
        photos << BugGuide::Photo.new(
          thumbnail_url: tr.css('img')[0][:src],
          id: tr.children[1].text.to_i,
          url: tr.children[1].css('a')[0][:href],
          title: tr.children[2].text,
          date: tr.children[3].text,
          state: tr.children[4].text,
          county: tr.children[5].text,
          city_location: tr.children[6].text,
          taxon: BugGuide::Taxon.new(
            name: tr.children[7].text,
            id: tr.children[7].css('a')[0][:href].to_s[/\d+$/, 0],
            url: tr.children[7].css('a')[0][:href]
          )
        )
      end
    end
    photos
  end

  # DarwinCore Simple Multimedia mapping
  # http://rs.gbif.org/terms/1.0/Multimedia

  # DarwinCore Simple Multimedia identifier
  alias_method :identifier, :id

  # DarwinCore Simple Multimedia references (basically just a URL)
  alias_method :references, :url

  # DarwinCore Simple Multimedia date created
  alias_method :created, :date

  # DarwinCore Simple Multimedia media type
  def type
    "StillImage"
  end

  # DarwinCore Simple Multimedia media format, aka MIME type
  def format
    "image/jpeg"
  end

  # DarwinCore Simple Multimedia publisher, always BugGuide in this case
  def publisher
    "BugGuide"
  end
end
