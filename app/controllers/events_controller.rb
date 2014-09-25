# coding: utf-8
class EventsController < ApplicationController

  def new
    @trip = current_user.trips.find(params[:trip_id])
    @event = @trip.events.build
    render :layout => false if request.xhr?
  end

  def edit
    @trip = current_user.trips.find(params[:trip_id])
    @event = @trip.events.find(params[:id])
    render :layout => false if request.xhr?
  end

  def create
    @trip = current_user.trips.find(params[:trip_id])
    improve_dates_from_params
    @event = @trip.events.new(params[:event])

    if @event.save
      flash[:notice] = 'Event added to the calendar.'
    else
      flash[:error]='Event was not saved! '+@event.errors.full_messages.join('. ')
    end
    flash[:anchor] = 'calendar'
    redirect_to trip_path(@trip)
  end

  def update
    @trip = current_user.trips.find(params[:trip_id])
    @event = @trip.events.find(params[:id])
    improve_dates_from_params
    if @event.update_attributes(params[:event])
      flash[:success] = 'Event updated.'
    else
      flash[:error]='Event was not saved! '+@event.errors.full_messages.join('. ')
    end
    flash[:anchor] = 'calendar'
    redirect_to trip_path(@trip)
  end

  def destroy
    @trip = current_user.trips.find(params[:trip_id])
    @event = @trip.events.find(params[:id])
    @event.destroy
    flash[:anchor] = 'calendar'
    redirect_to trip_path(@trip)
  end

private

  def improve_dates_from_params
    unless params[:event][:start_at].blank?
      params[:event][:start_at] = Date.strptime(params[:event][:start_at], '%m/%e/%Y')
    end
    unless params[:event][:end_at].blank?
      params[:event][:end_at] = Date.strptime(params[:event][:end_at], '%m/%e/%Y')
    end
  end

end
