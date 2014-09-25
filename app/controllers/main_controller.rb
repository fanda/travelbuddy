class MainController < ApplicationController

  before_filter :authenticate_user!, :only => [:user_profile, :user_settings]

  def index
    if user_signed_in?
      @messages = current_user.friend_updates.page(params[:page])
      countries = Travel.users(current_user.friend_ids).country
      @locations = current_user.friends_with_locations
    else
      @index = true
      @messages = Message.only_active.order('id DESC').page(params[:page])
      countries = Travel.country
      @locations = Hash.new
    end

    @country_heat = Hash.new(0)
    @country_users = Hash.new([])
    countries.each do |travel|
      @country_heat[travel.country] += 1
      next unless travel.user
      @country_users[travel.country] += [travel.user.name]
    end
  end

  def message
    if @message = Message.find(params[:id])
      @user = @message.user
      render
    else
      flash[:error] = t('message_not_found')
      redirect_to root_path
    end
  end

  def user_profile
    if @user = User.find_by_facebook_id(params[:uid])
      @message = @user.create_messages(false)
      @updates = @user.messages.my_updates
      @friends = @user.friends
      @trips   = @user.trips
      if current_user and @current_user != @user
        @time_matches = current_user.match(:time, [@user.id])
        @country_matches = current_user.match(:country, [@user.id])
        @time_messages = current_user.match_messages(
          :time,    @time_matches,    :include_country_messages => true
        )
        @country_messages = current_user.match_messages(
          :country, @country_matches, :include_time_messages    => true
        )
        @perfects = current_user.perfect_matches(@time_matches,@country_matches)
      end
    end
  end

  def user_settings
    if request.post?
      if current_user.update_attributes({:preference => params[:notify]})
        flash[:success] = t('user_settings_success')
        redirect_to root_path
      else
        flash[:error] = t('user_settings_error')
        redirect_to user_settings_path
      end
    else
      current_user
      render :layout => false if request.xhr?
    end
  end

  # only debug a test method
  #def try
  #  dbg current_user.fql('select uid, name, is_app_user from user where uid in (select uid2 from friend where uid1=me()) and is_app_user=1')
  #  render :action => 'index'
  #end

  # "SELECT post_id, message, app_data FROM stream WHERE app_id=#{AppConfig.fb_app_id} AND filter_key in (SELECT filter_key FROM stream_filter WHERE uid=me() AND type='newsfeed')" # moje příspěvky z tb

  # .facebook.friends(:installed => true)  ~ /me/?fields=installed
  # "SELECT uid, first_name, last_name, pic_square, current_location FROM user WHERE uid in (SELECT uid2 FROM friend WHERE uid1='#{current_user.facebook_uid}')"

end
