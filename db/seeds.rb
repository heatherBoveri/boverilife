# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

(1..5).each do
  tags = []
  l = Location.new({ country: 'Costa Rica', city: 'Playa Hermosa', order: 1, cost: 30, days: 9 })
  t = Trip.new(
    {
      matt_rating: 9,
      heather_rating: 7,
      min_flight_cost: 750,
      destination_airport: '',
      return_airport: '',
      max_flight_cost: 750,
      total_hours: 20,
      travel_hours: 1,
      name: 'Playa Hermosa',
      avg_flight_cost: 750,
      locations: [l]
    }
  )
  ['Adventure', 'Nature', 'Kid-Friendly', 'Family or Friends', 'Relaxation'].each do |tag|
    tags << Tag.new(value: tag, trip: t) unless t.tags.map(&:value).include?(tag)
  end
  t.save
  tags.each(&:save)
end

(1..5).each do
  l = Location.new({ country: 'United States of America', city: 'Staycation', order: 1, cost: 0, days: 9 })
  t = Trip.new(
    {
      matt_rating: 9,
      heather_rating: 7,
      min_flight_cost: 750,
      destination_airport: '',
      return_airport: '',
      max_flight_cost: 750,
      total_hours: 20,
      travel_hours: 1,
      name: 'Playa Hermosa',
      avg_flight_cost: 750,
      locations: [l]
    }
  )
  t.save
end
