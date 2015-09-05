class BugGuide::Photo < OpenStruct
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
    url = "http://bugguide.net/adv_search/bgsearch.php?"
    options.stringify_keys!
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
    url += params.join('&')
    photos = []
    # puts "fetching #{url}"
    open(url) do |response|
      html = Nokogiri::HTML(response.read)
      if html.to_s =~ /Too many results \(\d+\)/
        raise BugGuide::TooManyResultsException
      end
      names = []
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
            id: tr.children[7].css('a')[0][:href].to_s[/\d+$/, 1],
            url: tr.children[7].css('a')[0][:href]
          )
        )
      end
    end
    photos
  end
end