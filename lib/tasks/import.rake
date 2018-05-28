require 'open-uri'

namespace :import do
  desc 'Import trips from excel document'
  task trips: :environment do
    puts Rails.root.join('lib', 'tasks', 'trips.xlsx')

    xlsx = Roo::Excelx.new(Rails.root.join('lib', 'tasks', 'trips.xlsx'))
    # Location 1,#,$,Location 2,#,$,Location 3,#,$,Location 4,#,$,Total HR,Travel HR

    xlsx.sheet(0).each_with_index do |row, i|
      next if i == 0

      countries = ISO3166::Country.all.map(&:name).map(&:downcase)
      state = nil
      locations = []
      (
        [[row[0], row[1], row[2]], [row[3], row[4], row[5]], [row[6], row[7], row[8]], [row[9], row[10], row[11]]
      ]).each do |location, days, cost|
        next if location == '-' || location.nil? || location.empty?
        country = location.split(',').last.strip
        if !countries.include?(country.downcase)
          country = 'United States of America'
          state = location.split(',').last.strip
        end
        city = location.split(',').first
        locations << Location.new(country: country, city: city, days: (days || 0), cost: cost, state: state)
      end
      trip = Trip.new(locations: locations)

      if found_trip = Trip.find_by(name: trip.cities.uniq.map(&:titlecase).join('-'))
        locations.each do |l|
          found_location = found_trip.locations.select { |loc| loc.city == l.city }.first
          if found_location
            found_location.update_attributes(
              country: l.country, city: l.city, days: l.days, cost: l.cost, state: l.state, trip: found_trip)
          end
        end
        found_trip.save!
        puts "Updated trip: #{found_trip.locations.map(&:city)}"
      else
        trip.save!
        puts "Created trip: #{trip.name}"
      end

      trip = found_trip ? found_trip : trip
      trip.total_hours = row[12] unless row[12].nil?
      trip.travel_hours = row[13] unless row[13].nil?
      trip.min_flight_cost = row[14] unless row[14].nil?
      trip.max_flight_cost = row[15] unless row[15].nil?
      trip.avg_flight_cost = row[16] unless row[16].nil?
      trip.heather_rating = row[18] unless row[18].nil?
      trip.matt_rating = row[19] unless row[19].nil?
      trip.year = row[20] unless row[20].nil?
      trip.ignore_in_lifetime = ActiveModel::Type::Boolean.new.cast(row[21]) unless row[21].nil?
      trip.ignore_destination_flight = ActiveModel::Type::Boolean.new.cast(row[22]) unless row[22].nil?
      trip.ignore_return_flight = ActiveModel::Type::Boolean.new.cast(row[23]) unless row[23].nil?

      if row[17].present?
        row[17].to_s.split(', ').each do |tag|
          Tag.find_or_create_by(value: tag, trip_id: trip.id) if Tag::NAMES.include?(tag)
        end
      end
      trip.save!
      puts "Saved trip: #{trip.tags.map(&:value)}"
    end
  end

  desc 'Import locations from the web document'
  task locations: :environment do
    Location.all.each do |location|
      puts "."
      travelandleisure = "http://www.travelandleisure.com/travel-guide/#{location.city.titlecase.gsub(' ', '-')}"
      doc = Nokogiri::HTML(open(URI.escape(travelandleisure))) rescue nil
      if doc.present?
        titles = doc.css('.article-tips__title').map(&:text)
        content = doc.css('.article-tips__content').map { |c| c.text.gsub(/\n/, '').strip }
        titles.each_with_index do |t, i|
          fact = Fact.find_or_create_by!(key: t.gsub(location.city.titlecase, '').strip, value: content[i], location_id: location.id)
          fact.update_attributes(key: t.gsub(location.city.titlecase, '').strip, value: content[i], location_id: location.id)
        end
      else
        puts "Couldn't find t&l article #{location.city}"
      end

      doc = Nokogiri::HTML(open(URI.escape("http://www.jauntaroo.com/destinations/view/#{location.city.gsub(' ', '-')}/")))
      if doc.present?
        location.update_attributes(summary: doc.css('.description').text.gsub(/Description/, '').strip)

        t = doc.css('.details-todos').children.map { |t| t.text.strip.split("\n") }.flatten.map(&:strip).reject(&:empty?)
        t.delete_if do |item|
          item.match(/Visit Website/) || item.match(/Cost: /) || item.match(/Contact: /) || item.match(/Photo Credit:/)
        end

        bad_values = t.values_at(*t.each_index.select(&:even?)).select { |item| item.match(/\./)}
        t.delete_if { |item| bad_values.include?(item) }

        if t.count.odd?
          bad_values = t.values_at(*t.each_index.select(&:odd?)).select { |item| item.match(/\./)}
          t.delete_if { |item| bad_values.include?(item) }
        end

        puts "Cannot find Jauntaroo #{location.city}" unless t.any?

        t.each_slice(2).to_a.each do |key, todo|
          next if key.size > 60
          Todo.find_or_create_by(key: key, value: todo, location_id: location.id)
        end
      end

      wikitravel = "https://wikitravel.org/en/#{location.city.gsub(' ', '_')}"
      wikitraveldoc = Nokogiri::HTML(open(URI.escape(wikitravel))) rescue nil
      if wikitraveldoc.present?
        default = 'https://wikitravel.org/upload/shared//6/6a/Default_Banner.jpg'
        summary = wikitraveldoc.xpath('//table//p')[0..4].map { |p| p.text.strip.gsub(/\[\d+\]/, '').gsub(/\"/, '') }.reject(&:empty?)
        if summary.first.match(/more than one place called/) || summary.first.match(/There are several places in the world called/)
          state_link = /#{Regexp.quote((location.state || 'no state available').gsub(' ', '_'))}/
          country_link = /#{Regexp.quote(location.country.gsub(' ', '_'))}/
          city_link = /#{Regexp.quote(location.city.gsub(' ', '_'))}/
          search = wikitraveldoc.css('#mw-content-text  a').find { |link|
            (link['href'].match(state_link) || link['href'].match(country_link)) && link['href'].match(city_link)
          }
          if matching_link = search
            wikitravel = "https://wikitravel.org/#{matching_link['href']}"
            wikitraveldoc = Nokogiri::HTML(open(URI.escape(wikitravel)))
            summary = wikitraveldoc.xpath('//table//p')[0..4].map do |p|
              p.text.strip.gsub(/\[\d+\]/, '').gsub(/\"/, '')
            end.reject(&:empty?)
          end
        end
        wiki = []
        summary = summary.each do |s|
          s = s.gsub("Discussion on defining district borders for #{location.city} is in progress.", '')
          s = s.gsub(' If you know the city pretty well, please share your opinion on the talk page.', '')
          wiki << s if wiki.join.length < 1500 && s.strip.present?
        end
        location.update_attributes(wiki: wiki)

        if location.image.nil? || location.image.src == default
          src = wikitraveldoc.nil? ? default :  wikitraveldoc.css('//*[@id="mf-pagebanner"]/div[1]/p/a/img').map { |i| i['src'] }.first
          image = Image.find_by(src: src, link: wikitravel, location: location)
          attributes = { src: src, link: wikitravel, location: location }
          image ? image.update_attributes(attributes) : Image.find_or_create_by(attributes)
        end
      else
        puts "Couldn't find summary #{location.city}"
      end
    end
  end
end
