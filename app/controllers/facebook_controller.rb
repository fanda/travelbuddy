class FacebookController < ApplicationController

  before_filter :authenticate_user!, :except => [:welcome, :friend_info]

  def invite
    params[:fin] ||= false # default value for alert action condition

    if request.xhr?
      render :js=>"inviteOnFacebook('#{current_user.name} #{t('invitation_text')}');"
    else
      render
    end
  end

  def share
    if request.xhr?
      render :layout => false
    end
    # no action here - only view
  end

  # ajax method - information for popover - if requested
  def friend_info
    @user = User.find_by_facebook_id(params[:uid])
    @message = @user.active_message
    render :layout => false
  rescue
    render :text => t('popover_not_loaded')
  end

  def welcome
    if current_user
      flash[:facebook_canvas] = true
      redirect_to signout_services_path
    end
    @facebook_canvas = true
  end

  def not_in_app_friends
    @users_countries = current_user.travels.country.map {|t| t.country }
    @friends = current_user.facebook_friends_with_location_info_and_not_in_app
    @fb_friends_heat = Hash.new(0)
    render :layout => false
  end

end
