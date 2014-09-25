class TravelsController < ApplicationController
  include CountryNameHelper

  before_filter :authenticate_user!

  # My Travel Preferences form
  def new
    @countries   = []
    @preferences = []
    # load travel preferences and show them
    current_user.travels.each do |travel|
      if travel.country.blank?
        @preferences.push travel
      else
        @countries.push travel.country
      end
    end
  end

  # My Travel Preferences - process form - POST data
  def create
    @existing_countries = current_user.travels.country
    # save update User with travel_attributes (helper method below)
    if current_user.update_attributes(travels_attributes)
      current_user.map = params[:map] # make map from svg data
      current_user.create_messages
      new_countries = @country_codes - @existing_countries.map {|t| t.country }
      current_user.notify_perfect_matches new_countries
      flash[:success] = t('create_travel_success')
      flash[:from_travel_create] = true
      redirect_to :action => 'match'
    else
      # invalid attributes - transform them to show
      @countries = params[:countries].collect {|c|c.first}||[]
      @preferences = params[:preference].values.map do |preference|
        OpenStruct.new(preference) # hash with method-like access
      end
      # TODO better errors report
      @error = t('create_travel_error')
      render :action => 'new'
    end
  end


  def match
    @preferences = []
    countries = []
    current_user.travels.each do |travel|
      if travel.country
        countries << travel.country
      else
        @preferences << travel
      end
    end
    @preferences = @current_user.travels.time
    @country_matches = @current_user.match(:country)
    @time_matches = @current_user.match(:time)
    @time_messages = @current_user.match_messages(
      :time,    @time_matches,    :include_country_messages => true
    )
    @country_messages = @current_user.match_messages(
      :country, @country_matches, :include_time_messages    => true
    )
    # use loaded matches, so no more database request required (RE-USE)
    @perfects = @current_user.perfect_matches(@time_matches,@country_matches)

    @checkins = @current_user.matched_friends_checkins(countries)
    @photos   = @current_user.matched_friends_photos(countries)

    @country_heat = Hash.new(0)

    @country_matches.each do |travel|
      @country_heat[travel.country] += 1
    end
    @friends_locations = @current_user.facebook_friends_locations(countries)
    @friends_locations.each do |friends_location|
      friends_location[1].values.each do |location|
        @country_heat[location[1]] += 1 # location = [ country_name, country_code ]
      end
    end

    @photos.values.each do |countries_posts|
      countries_posts.keys.each do |country|
        @country_heat[country] += 1
      end
    end

    @time_heat = Hash.new(0)
    # we use loop in view /travels/match for performance reason
  end

private

  # transform form params to saveable attributes
  def travels_attributes
    @attributes = Hash.new
    cud_countries # special function needed
    params[:preference].values.each_with_index do |dates, i|
      @attributes[i] = dates
      # if user want to remove time preference
      if dates[:id] and dates[:begins].blank? and dates[:ends].blank?
        @attributes[i].merge!(:_destroy => true)
      end
    end
    user_travels = {:travels_attributes => @attributes}
  end

  # Create|Update|Delete (cud) countries
  def cud_countries
    index = 0
    countries = params[:countries]||[] # countries from form
    existing = @existing_countries # countries from DB
    @country_codes = []
    popularity = compute_country_travels_popularity
    countries.each  do |code|
      @attributes[index.to_s] = {:country => code.first}
      @country_codes << code.first
      # rewrite existing country if exists
      if travel = existing.at(index)
        @attributes[index.to_s][:id] = travel.id
      end
      @attributes[index.to_s][:popularity] = popularity[code.first]||0
      index += 1
    end
    # if more countries is in DB than in form, delete unwanted countries
    while existing.size > index
      travel = existing.at(index)
      @attributes[index.to_s] = {:id => travel.id, :_destroy => true}
      index += 1
    end
  end

  def compute_country_travels_popularity
    popularity = Hash.new(0) # init hash with zeros
    # get all countries of all friends and make histogram
    Travel.users(current_user.friend_ids).country.each do |travel|
      popularity[travel.country] += 1
    end
    popularity
  end

end
