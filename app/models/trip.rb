require 'open-uri'

class Trip < ApplicationRecord
  has_many :locations, inverse_of: :trip, autosave: true, dependent: :destroy
  has_many :tags, inverse_of: :trip, autosave: true, dependent: :destroy
  has_many :todos, through: :locations, dependent: :destroy
  accepts_nested_attributes_for :tags, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :locations, reject_if: :all_blank, allow_destroy: true

  RETIREMENT = 1991 + 60
  KID_BIRTH = 2020
  SABBATICAL = 2023

  validate :has_location, :no_duplicate_locations

  before_save :set_name, :set_location_cost, :set_images, :set_avg_flight_cost, :set_location_order, :set_peace_index

  def set_location_order
    locations.each_with_index do |location, index|
      location.order = index + 1 unless location.order.present?
    end
  end

  def set_name
    self.name = cities.uniq.map(&:titlecase).join('-')
  end

  def climate
    link = "https://wikitravel.org/en/#{locations.first.city.titlecase.gsub(' ', '_')}"
    doc = Nokogiri::HTML(open(URI.escape(link))) rescue nil
    stats = doc.css('#climate_table').text.split("\n").reject { |c| c.empty? }
  end

  def icons
    @icons ||= tag_values.map { |tag| [tag, Tag::NAMES_TO_ICONS[tag]] }
  end

  def tag_values
    @tag_values ||= tags.map(&:value).reject(&:empty?).sort
  end

  def set_images
    default = 'https://wikitravel.org/upload/shared//6/6a/Default_Banner.jpg'
    locations.each do |location|
      wikitravel = "https://wikitravel.org/en/#{location.city.gsub(' ', '_')}"
      wikitraveldoc = Nokogiri::HTML(open(URI.escape(wikitravel))) rescue nil
      if location.image.nil? || location.image.src == default
        src = wikitraveldoc.nil? ? default :  wikitraveldoc.css('//*[@id="mf-pagebanner"]/div[1]/p/a/img').map { |i| i['src'] }.first
        image = Image.new(src: src, link: wikitravel, location: location)
      end
    end
  end

  def set_avg_flight_cost
    return 0 unless min_flight_cost || max_flight_cost
    self.avg_flight_cost = (min_flight_cost + max_flight_cost) / 2
  end

  def set_location_cost
    locations.each do |location|
      next if location.city.empty? || (location.cost.present? && location.cost != 0)
      begin
        doc = parse_location(location.country, location.city)
        next if doc.nil?
        text = doc.css('#wrapper > div.container > div > div > div.innercolumnfat.city-info > p').text
        if non_us_currency = text.match(/\(\$\d+\)/)
          location.cost = non_us_currency.to_s[2..-2].to_i
        else
          location.cost = text.match(/\$\d+/).to_s.partition('$').last
        end
      rescue OpenURI::HTTPError, URI::InvalidURIError => e
        location.cost = 0
      end
    end
  end

  def vacation_days
    case length
    when 3 then 1
    when 4, 5 then 2
    when 9 then 5
    when 16 then 10
    when 23 then 15
    when 2 then 0
    else 0
    end
  end

  def images
    locations.map { |l| [l, l.image] }
  end

  def cities
    locations.map(&:city)
  end

  def cost_to_stay
    locations.sum { |location| location.days * location.cost }
  end

  def flight_hours
    return 0 if !(total_hours || travel_hours)
    total_hours - travel_hours
  end

  def total_flight_cost
    flight_cost = avg_flight_cost || 0
    ((ignore_return_flight || ignore_destination_flight) ? flight_cost : (flight_cost * 2)).round
  end

  def total_cost
    cost_to_stay + total_flight_cost
  end

  def badge_color(score)
    integer_score = score.to_i
    case
    when integer_score > 7 then 'badge-success'
    when integer_score > 4 then 'badge-warning'
    when integer_score > 0 then 'badge-danger'
    else 'badge-secondary'
    end
  end

  def rating
    if matt_rating && heather_rating
      (matt_rating + heather_rating) / 2
    elsif matt_rating
      matt_rating
    elsif heather_rating
      heather_rating
    else
      "Not Rated"
    end
  end

  def cost_per_day
    cost_to_stay/length
  end

  def length
    locations.sum(&:days)
  end

  def hours_of_travel
    "#{travel_hours}/#{total_hours} hours"
  end

  def average_peace_index_score
    peace = locations.map { |l| l.peace_index if l.peace_index != 0 }.compact
    return 0 if peace.empty?
    average = (peace.reduce(:+) / peace.size.to_f).round(0)
  end

  private

  def set_peace_index
    wikitraveldoc = Nokogiri::HTML(open(URI.escape('https://en.wikipedia.org/wiki/Global_Peace_Index')))
    locations.each do |location|
      next unless location.peace_index.zero?
      wikitraveldoc.xpath('//table[.//td[contains(., "Bolivia")]]//tr').each do |tr|
        if location.country == "United States of America"
          country = 'united states'
        else
          country = location.country.downcase
        end

        location.peace_index = tr.xpath('./td')[1].text if tr.xpath('./td').first.text.downcase.match(country)
      end
    end
  rescue
  end

  def parse_location(region, city)
    Nokogiri::HTML(open("https://www.budgetyourtrip.com/#{region.gsub(' ', '-')}/#{city.gsub(' ', '-')}"))
  rescue
  end

  def has_location
    errors.add(:locations, "At least one location is required") unless locations.any?
  end

  def no_duplicate_locations
    locs = locations.map(&:city)
    errors.add(:locations, "There are duplicate locations #{locs}") if locs.size != locs.uniq.size
  end
end
