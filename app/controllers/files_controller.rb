class FilesController < ApplicationController

  before_filter :authenticate_user!


  def new
    @trip = current_user.trips.find(params[:trip_id])
    @attachment = @trip.attachments.build
    render :layout => false if request.xhr?
  end

  def create
    @trip = current_user.trips.find(params[:trip_id])
    if params[:attachment][:name].blank? and params[:attachment][:file]
      params[:attachment][:name] = params[:attachment][:file].original_filename
    end
    @attachment = @trip.attachments.new(params[:attachment])

    if @attachment.save
      flash[:success] = 'File was successfully uploaded.'
    else
      flash[:error] = 'File upload failed. ' + @attachment.errors.full_messages.join('. ')
    end
    flash[:anchor] = 'files'
    redirect_to trip_path(@trip)
  end

  def destroy
    @trip = current_user.trips.find(params[:trip_id])
    @attachment = @trip.attachments.find(params[:id])
    @attachment.destroy
    flash[:notice] = 'File was successfully deleted'
    flash[:anchor] = 'files'
    redirect_to trip_path(@trip)
  end

end
