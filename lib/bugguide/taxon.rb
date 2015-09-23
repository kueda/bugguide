#encoding: utf-8
class BugGuide::Taxon
  NAME_PATTERN = /[\w\s\-\'\.]+/
  attr_accessor :id, :name, :scientific_name, :common_name, :url

  def initialize(options = {})
    options.each do |k,v|
      send("#{k}=", v)
    end
    self.url ||= "http://bugguide.net/node/view/#{id}"
  end

  def name=(new_name)
    if new_name =~ /subgenus/i
      self.scientific_name ||= new_name.gsub(/subgenus/i, '')[/[^\(]+/, 0]
    elsif matches = new_name.match(/group .*\((#{NAME_PATTERN})\)/i)
      self.scientific_name ||= matches[1]
    elsif matches = new_name.match(/(#{NAME_PATTERN}) \((#{NAME_PATTERN})\)/)
      self.scientific_name ||= matches[1]
      self.common_name ||= matches[2]
    else
      self.scientific_name ||= new_name[/[^\(]+/, 0]
    end
    @name = new_name.strip if new_name
  end

  def scientific_name=(new_name)
    @scientific_name = new_name.strip if new_name
  end

  def common_name=(new_name)
    @common_name = new_name.strip if new_name
  end

  def rank=(new_rank)
    @rank = new_rank.downcase
    @rank = nil if @rank == 'no taxon'
  end

  def rank
    return @rank if @rank
    @rank = taxonomy_html.css('.bgpage-roots a').last['title'].downcase
  end

  def ancestors
    return @ancestors if @ancestors
    @ancestors = []
    nbsp = Nokogiri::HTML("&nbsp;").text
    @ancestors = taxonomy_html.css('.bgpage-roots a').map do |a|
      next unless a['href'] =~ /node\/view\/\d+\/tree/
      t = BugGuide::Taxon.new(
        id: a['href'].split('/')[-2],
        name: a.text.gsub(nbsp, ' '),
        url: a['href'],
        rank: a['title']
      )
      if name_matches = t.name.match(/(#{NAME_PATTERN})\s+\((#{NAME_PATTERN})\)/)
        t.common_name = name_matches[1]
        t.scientific_name = name_matches[2]
      elsif name_matches = t.name.match(/(#{NAME_PATTERN})\s+\-\s+(#{NAME_PATTERN})/)
        t.common_name = name_matches[2]
        t.scientific_name = name_matches[1]
      end
      next if t.scientific_name == scientific_name
      t
    end.compact
  end

  def taxonomy_html
    return @taxonomy_html if @taxonomy_html
    open("http://bugguide.net/node/view/#{id}/tree") do |response|
      @taxonomy_html = Nokogiri::HTML(response.read)
    end
  end

  # http://bugguide.net/adv_search/taxon.php?q=Sphecidae returns
  # 117327||Apoid Wasps (Apoidea)- traditional Sphecidae|2302 135|Sphecidae|Thread-waisted Wasps|2700 
  def self.search(name)
    url = "http://bugguide.net/adv_search/taxon.php?q=#{name}"
    f = open(url)
    taxa = []
    open(url) do |f|
      f.read.split("\n").each do |row|
        row = row.split('|').compact.map(&:strip)
        taxa << BugGuide::Taxon.new(
          id: row[0], 
          name: row[1], 
          scientific_name: row[1], 
          common_name: row[2]
        )
      end
    end
    taxa
  end

  def self.find(id)
    taxon = BugGuide::Taxon.new(id: id)
    taxon.name = taxon.taxonomy_html.css('.node-title h1').text
    taxon.scientific_name = taxon.taxonomy_html.css('.node-title i').text
    taxon.common_name = taxon.taxonomy_html.css('.node-title').text.split('-').last
    taxon
  end

  # DarwinCore mapping
  alias_method :taxonID, :id
  alias_method :scientificName, :scientific_name
  alias_method :vernacularName, :common_name
  alias_method :taxonRank, :rank
  def higherClassification
    ancestors.map(&:scientific_name).join(' | ')
  end

end
