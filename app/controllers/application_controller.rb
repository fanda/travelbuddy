class ApplicationController < ActionController::Base
  include CountryNameHelper

  protect_from_forgery

  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :used_service
  helper_method :current_user_friends

  helper_method :most_popular_countries

  before_filter :www_redirect

protected

  def www_redirect
    if Rails.env.production? and request.host =~ /^www\./
      redirect_to request.url.sub(/http:\/\/www\./,'http://')
    end
  end

  def most_popular_countries
    if user_signed_in?
      populars = @current_user.most_popular_countries
      if populars.any?
        return "#{populars.map {|t| country_name t.country }.join(', ')}"
      end
    end
    AppConfig.default_search_term
  rescue
    AppConfig.default_search_term
  end

  def dbg item
    @debug ||=[]
    @debug << item
  end

private

  def redirect_to_domain
    if Rails.env.production? and request.host =~ /heroku.com/
      redirect_to request.url.sub(/heroku\.com/, '.co')
    end
  end

  def current_user
    cookies[:at] = session[:at] if session[:at]
    @current_user ||= User.find_by_id(session[:user_id]) if session[:user_id]
  rescue
    false
  end

  def user_signed_in?
    current_user ? true : false
  end

  def current_user_friends
    current_user ? @friends ||= current_user.friends : []
  end

  def used_service
    @used_service ||= current_user.services.find(session[:service_id])
  rescue
    Service.new
  end


  def authenticate_user!
    if !current_user
      flash[:error] = 'You need to sign in before accessing this page!'
      redirect_to root_path
    end
  end

  def user_not_signed_in!
    if current_user
      #flash[:error] = 'You already are signed in'
      redirect_to root_path
    end
  end

end
