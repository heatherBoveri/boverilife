class TripsController < ApplicationController
  before_action :set_trip, only: [:show, :edit, :update, :destroy]

  # GET /trips
  # GET /trips.json
  def index
    @trips = Trip.all
    @locations = Location.all
  end

  def ratings
    @top_trips = Trip.where('heather_rating > 8 OR matt_rating > 8').sort_by(&:rating).reverse
    @matt_trips = Trip.where('matt_rating > 8').order(matt_rating: 'desc')
    @heather_trips = Trip.where('heather_rating > 8').order(heather_rating: 'desc')
    @not_rated = Trip.where('heather_rating is null OR matt_rating is null')
  end

  def lifetime
    @trips = lifetime_trips(Trip.where(ignore_in_lifetime: false).order(matt_rating: 'desc', heather_rating: 'desc'))
    sorted_trips = {}
    @cost = {}
    @daily = {}
    @ratings = {}
    @flights = {}
    @hours = {}
    @trips.each { |trip| sorted_trips[trip.first - 1991] = trip.second }
    sorted_trips.delete_if { |k| k > 75 }
    sorted_trips.each { |k, v| @cost[k] = v.map(&:total_cost).reduce(0, :+) }
    sorted_trips.each { |k, v| @daily[k] = v.map(&:cost_per_day).reduce(0, :+) }
    sorted_trips.each { |k, v| @ratings[k] = v.map(&:rating).select { |r| r.is_a? Integer }.reduce(0, :+) }
    sorted_trips.each { |k, v| @flights[k] = v.map(&:total_flight_cost).reduce(0, :+) }
    sorted_trips.each { |k, v| @hours[k] = v.map(&:flight_hours).select { |r| r.is_a? Integer }.reduce(0, :+) }
  end

  def categories
    @costly_trips = Trip.all.order(avg_flight_cost: 'DESC').limit(50)
    @cheapest_flights = Trip.all.order(avg_flight_cost: 'ASC').limit(50)
    @longest_flights = Trip.all.order(total_hours: 'DESC').limit(50)
    @cheapest_to_stay = Trip.all.sort_by { |trip| trip.cost_to_stay }.reject { |trip| trip.cost_to_stay.zero? }[0..30]
  end

  def retirement
    @trips = Tag.where(value: 'Retirement').map(&:trip).group_by { |tag|
      tag.year if tag.year
    }.sort_by { |year, trips| year || 0 }.select { |year, trip| year.nil? || year >= Trip::RETIREMENT }
  end

  def kids
    @trips = Tag.where(value: 'Kid-Friendly').map(&:trip).group_by { |tag|
      tag.year if tag.year
    }.sort_by { |year, trips| year || 0 }
     .select { |year, trip| year.nil? || (year >= Trip::KID_BIRTH && year < Trip::RETIREMENT) }
  end

  def ignored
    @trips = Trip.where(ignore_in_lifetime: true)
  end

  # GET /trips/1
  # GET /trips/1.json
  def show
    @todos = @trip.locations.map(&:todos).flatten
  end

  # GET /trips/new
  def new
    @trip = Trip.new
    Cities.data_path = "#{Rails.root}/public/assets/cities"
    @countries = ISO3166::Country.all
    @airports = Airports.all.map { |airport| ["#{airport.name} (#{airport.iata})", airport.iata]  }
  end

  # GET /trips/1/edit
  def edit
    Cities.data_path = "#{Rails.root}/public/assets/cities"
    @countries = ISO3166::Country.all
    @airports = Airports.all.map { |airport| ["#{airport.name} (#{airport.iata})", airport.iata]  }
  end

  # POST /trips
  # POST /trips.json
  def create
    @trip = Trip.new(trip_params)

    respond_to do |format|
      if @trip.save
        format.html { redirect_to @trip, notice: 'Trip was successfully created.' }
        format.json { render :show, status: :created, location: @trip }
      else
        format.html { render :new }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /trips/1
  # PATCH/PUT /trips/1.json
  def update
    respond_to do |format|
      if @trip.update(trip_params)
        format.html { redirect_to @trip, notice: 'Trip was successfully updated.' }
        format.json { render :show, status: :ok, location: @trip }
      else
        format.html { render :edit }
        format.json { render json: @trip.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trips/1
  # DELETE /trips/1.json
  def destroy
    @trip.destroy
    respond_to do |format|
      format.html { redirect_to trips_url, notice: 'Trip was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_trip
    @trip = Trip.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def trip_params
    params.require(:trip).permit(
      :year,
      :matt_rating,
      :heather_rating,
      :min_flight_cost,
      :max_flight_cost,
      :better_with_kids,
      :destination_airport,
      :return_airport,
      :total_hours,
      :travel_hours,
      :ignore_destination_flight,
      :ignore_return_flight,
      :ignore_in_lifetime,
      tags_attributes: [:id, :value, :_destroy],
      locations_attributes: [:id, :country, :city, :cost, :days, :state, :order, :_destroy])
  end

  def lifetime_trips(trips)
    years_of_trips = []
    @used_trips = trips.select { |t| t.year.present? }
    trip_count = Trip.count

    (2018..2080).each do |year|
      # Find already determined trips
      year_trips = trips.select { |t| t.year == year }
      cost = year_trips.sum(&:total_cost)
      vacation_days = year_trips.sum(&:vacation_days)

      if year < Trip::KID_BIRTH
        year_days_available = 10
      elsif year < Trip::SABBATICAL
        year_days_available = 13
      else
        year_days_available = 15
      end

      # Pick a trip
      while vacation_days < year_days_available || cost < 17000
        matching_trip = trips.find do |t|
          if t.year.nil? && !@used_trips.include?(t) && !year_trips.map(&:name).include?(t.name)
            if year < 2050
              ((vacation_days + t.vacation_days) <= 10) && ((cost + t.total_cost) <= 15000)
            else
              (cost + t.total_cost) <= 15000 && year_trips.count < 3
            end
          end
        end
        if matching_trip.present?
          year_trips += [matching_trip]
          @used_trips += [matching_trip]
          cost += matching_trip.total_cost
          vacation_days += matching_trip.vacation_days
        else
          break
        end
      end
      cost = year_trips.sum(&:total_cost)
      vacation_days = year_trips.sum(&:vacation_days)

      years_of_trips << [year, year_trips, cost, vacation_days]
    end
    years_of_trips
  end
end
