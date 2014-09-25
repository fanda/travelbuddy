class TripsController < ApplicationController

  before_filter :authenticate_user!

  def show
    @countries   = []
    @preferences = []
    @month = (params[:month] || (Time.zone || Time).now.month).to_i
    @year = (params[:year] || (Time.zone || Time).now.year).to_i
    @shown_month = Date.civil(@year, @month)
    # load travel preferences and show them
    unless @trip = Trip.find(params[:id])
      redirect_to '/404.html'
      return
    end
    if @user_own_trip = @trip.users.include?(current_user)
      @files = @trip.attachments
    end
    @user_invited_trip = @trip.invitees.include?(current_user)
    @user_waiting_trip = @trip.waitings.include?(current_user)

    @country_message = @trip.message_country
    @active_tab = flash[:anchor] ? flash[:anchor].to_sym : nil

    i = 0
    @trip.travels.each do |travel|
      if travel.country.blank?
        @preferences.push travel
        @trip.events.build({  color: Event::PREFERENCES_COLORS[i],
          start_at: travel.begins, end_at: travel.ends, name: "#{(i+=1).ordinalize} preference"
        })
      else
        @countries.push travel.country
      end
    end
    # methods defined by Calendar_Event gem
    start_d, end_d = Event.get_start_and_end_dates(@shown_month)
    @event_strips  = Event.create_event_strips(start_d, end_d, @trip.events)
    @users = @trip.users
  end

  def new
    @countries   = []
    @preferences = []
    @trip = current_user.trips.build
  end

  def create
    @existing_countries = []
    @trip = current_user.trips.create(travels_attributes.merge(params[:trip]))
    if not @trip.errors.any?
      @trip.map = params[:map]

      # make message to Friend updates; helper method here
      country_message = @trip.message_country
      current_user.make_message(
        "created new trip group #{view_context.link_to @trip.name, trip_path(@trip)} to #{country_message}"
      )

      flash[:success] = t('create_trip_success')
      redirect_to trip_path(@trip)
    else
      # invalid attributes - transform them to show
      @countries = params[:countries]||[].collect {|c|c.first}
      @preferences = params[:preference].values.map do |preference|
        OpenStruct.new(preference) # hash with method-like access
      end
      @error = t('create_trip_error') +' '+ @trip.errors.full_messages.join('. ')
      render :action => 'new'
    end
  end

  def update
    unless @trip = current_user.trips.find(params[:id])
      redirect_to '/404.html'
      return
    end
    @existing_countries = @trip.travels.country
    if @trip.update_attributes(travels_attributes.merge(params[:trip]))
      @trip.map = params[:map]
      flash[:success] = t('update_trip_success')
      redirect_to trip_path(@trip)
    else
      # invalid attributes - transform them to show
      @countries = params[:countries].collect {|c|c.first}||[]
      @preferences = params[:preference].values.map do |preference|
        OpenStruct.new(preference) # hash with method-like access
      end
      @error = t('update_trip_error')
      render :action => 'edit'
    end
  end

  # invitation form and his post action
  def invite_friends
    unless @trip = current_user.trips.find(params[:id])
      redirect_to '/404.html'
      return
    end
    if request.post?
      if params[:users] =~ /(\d+\s*,\s*)*\d*/
        @trip.invite_users_with_facebook_ids params[:users].split(',')
      end
      flash[:success] = 'All invitations sent.'
      redirect_to trip_path(@trip)
    else
      @pals = @trip.pals_of current_user
      render :layout => false if request.xhr?
    end
  end

  # invited user rejected the invitation
  def reject
    unless @trip = Trip.find_by_id(params[:id])
      redirect_to '/404.html'
      return
    end
    flash[:success] = 'Invitation was rejected'
    @trip.invitees.delete(current_user)
    redirect_to trip_path(@trip)
  end

  # invited user accepted the invitation
  def accept
    unless @trip = Trip.find_by_id(params[:id])
      redirect_to '/404.html'
      return
    end
    @trip.users << current_user
    @trip.invitees.delete(current_user)
    flash[:success] = 'Now you are in this group'
    redirect_to trip_path(@trip)
  end

  # user sent request to join the trip
  def join
    unless @trip = Trip.find_by_id(params[:id])
      redirect_to '/404.html'
      return
    end
    flash[:success] = 'Your request was sent'
    @trip.save_request(current_user)
    redirect_to trip_path(@trip)
  end

  # trip member accepted user who sent the request
  def accept_user
    unless @trip = current_user.trips.find(params[:trip_id])
      redirect_to '/404.html'
      return
    end
    if user = User.find_by_facebook_id(params[:id])
      @trip.users << user
      @trip.waitings.delete(user)
      flash[:success] = 'User was accepted in this group'
    else
      flash[:error] = 'No such user to accept'
    end
    flash[:anchor] = 'requests' if @trip.waitings.any?
    redirect_to trip_path(@trip)
  end


  # trip member denied user who sent the request
  def deny_user
    unless @trip = current_user.trips.find(params[:trip_id])
      redirect_to '/404.html'
      return
    end
    flash[:success] = 'User was denied'
    @trip.waitings.delete(User.find_by_facebook_id(params[:id]))
    flash[:anchor] = 'requests' if @trip.waitings.any?
    redirect_to trip_path(@trip)
  end


  # trip member leaved the trip
  def leave
    unless @trip = current_user.trips.find(params[:id])
      redirect_to '/404.html'
      return
    end
    flash[:success] = 'You have been removed from trip group'
    @trip.users.delete(current_user)
    redirect_to trip_path(@trip)
  end

protected

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
    trip_travels = {:travels_attributes => @attributes}
  end

  # Create|Update|Delete (cud) countries
  def cud_countries
    index = 0
    countries = params[:countries]||[] # countries from form
    existing = @existing_countries # countries from DB
    countries.each  do |code|
      @attributes[index.to_s] = {:country => code.first}
      # rewrite existing country if exists
      if travel = existing.at(index)
        @attributes[index.to_s][:id] = travel.id
      end
      index += 1
    end
    # if more countries is in DB than in form, delete unwanted countries
    while existing.size > index
      travel = existing.at(index)
      @attributes[index.to_s] = {:id => travel.id, :_destroy => true}
      index += 1
    end
  end

end
