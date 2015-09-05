class BugGuide::Taxon
  attr_accessor :id, :name, :scientific_name, :common_name, :url

  def initialize(options = {})
    options.each do |k,v|
      send("#{k}=", v)
    end
  end

  def name=(new_name)
    if new_name =~ /subgenus/i
      self.scientific_name = new_name.gsub(/subgenus/i, '')[/[^\(]+/, 0]
    elsif matches = new_name.match(/([\w\s]+) \(([\w\s]+)\)/)
      self.scientific_name ||= matches[1]
      self.common_name ||= matches[2]
    else
      self.scientific_name = new_name.strip
    end
    @name = new_name.strip if new_name
  end

  def scientific_name=(new_name)
    @scientific_name = new_name.strip if new_name
  end

  def common_name=(new_name)
    @common_name = new_name.strip if new_name
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

end
