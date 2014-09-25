class ServicesController < ApplicationController
  before_filter :authenticate_user!, :except => [:create, :signin, :signup]

  before_filter :user_not_signed_in!,  :only => [:create, :signin, :signup]

  # callback: success
  # This handles signing in and adding an authentication service to existing accounts itself
  # It renders a separate view if there is a new user to create
  def create
    # get the service parameter from the Rails router
    params[:service] ? service_route = params[:service] : service_route = 'No service recognized (invalid callback)'
    # get the full hash from omniauth
    omniauth = request.env['omniauth.auth']

    if omniauth and params[:service]

      # map the returned hashes to our variables first - the hashes differs for every service

      # create a new hash
      @authhash = {:user => Hash.new}
      @authhash[:provider] = omniauth['provider'] ? omniauth['provider'] : ''

      if service_route == 'facebook'
        @authhash[:user][:email] = if omniauth['extra']['raw_info']['email']
                                    omniauth['extra']['raw_info']['email']
                                   else; ''; end
        @authhash[:user][:name]  = if omniauth['extra']['raw_info']['name']
                                    omniauth['extra']['raw_info']['name']
                                   else; ''; end
        @authhash[:user][:uid]   = if omniauth['extra']['raw_info']['id']
                                    omniauth['extra']['raw_info']['id'].to_s
                                   else; ''; end

        @authhash[:token] = omniauth['credentials']['token']

=begin  TODO Other services
      elsif ['google', 'yahoo', 'twitter', 'myopenid', 'open_id'].index(service_route) != nil
        @authhash[:email] = omniauth['user_info']['email'] ? omniauth['user_info']['email'] : ''
        @authhash[:name]  = omniauth['user_info']['name']  ? omniauth['user_info']['name']  : ''
        @authhash[:uid]   = omniauth['uid'] ? omniauth['uid'].to_s : ''
=end
      else
        # XXX DEBUG to output the hash that has been returned when adding new services
        render :text => omniauth.to_yaml
        return
      end

      if @authhash[:user][:uid] != '' and @authhash[:provider] != ''

        auth = Service.find_by_provider_and_uid(@authhash[:provider], @authhash[:user][:uid])

=begin  TODO if the user is currently signed in, he/she might want to add another account to signin
        if user_signed_in?
          if auth
            flash[:notice] ='Your account at '+@authhash[:provider].capitalize+' is already connected with this site.'
            redirect_to services_path
          else
            current_user.services.create!(:provider => @authhash[:provider], :uid => @authhash[:uid], :uname => @authhash[:name], :uemail => @authhash[:email])
            flash[:notice] = 'Your ' + @authhash[:provider].capitalize + ' account has been added for signing in at this site.'
            redirect_to services_path
          end
        end
=end
        unless user_signed_in?
          if auth
            # signin existing user
            # save actual access_token
            auth.update_attribute :token, @authhash[:token]
            cookies[:at] = auth.token
            session[:at] = auth.token
            # store auth session credentials
            session[:user_id] = auth.user.id
            session[:service_id] = auth.id

            auth.user.set_user_locations
            auth.user.check_and_save_new_friends_checkins
            #auth.user.check_and_save_new_feed_posts
            auth.user.check_and_save_new_photo_posts

            flash[:success] = 'Signed in successfully via ' + @authhash[:provider].capitalize + '.'
            redirect_to root_url
          else
            # this is a new user => create
            @newuser = User.new(@authhash[:user])
            @newuser.services.build(
              :provider => @authhash[:provider],
              :uid      => @authhash[:user][:uid],
              :uname    => @authhash[:user][:name],
              :uemail   => @authhash[:user][:email],
              :token    => @authhash[:token],
            )

            if @newuser.save
              # signin existing user
              # in the session his user id and the service id used for signing in is stored
              session[:user_id] = @newuser.id
              session[:service_id] = @newuser.services.first.id

              @newuser.check_and_save_new_friends_checkins

              flash[:success] = t 'create_user_success'
              flash[:notice] = t('create_user_notice').html_safe
              redirect_to new_travel_path
            else
              flash[:error] = t('create_user_error')
              redirect_to root_url
            end
          end
        end
      else
        flash[:error] =  'Error while authenticating via ' + service_route + '/' + @authhash[:provider].capitalize + '. The service returned invalid data for the user id.'
        redirect_to signin_path
      end
    else
      flash[:error] = 'Error while authenticating via ' + service_route.capitalize + '. The service did not return valid data.'
      redirect_to signin_path
    end
  end

  def index
    @services = current_user.services.order('provider asc')
  end

  def destroy
    # remove an authentication service linked to the current user
    @service = current_user.services.find(params[:id])

    if session[:service_id] == @service.id
      flash[:error] = 'You are currently signed in with this account!'
    else
      @service.destroy
    end

    redirect_to services_path
  end

  def signout
    if current_user
      begin
        Service.find(session[:service_id]).update_attribute :token, nil
      rescue
      end
      cookies[:at] = nil
      cookies.delete :at
      session[:at] = nil
      session[:user_id] = nil
      session[:service_id] = nil
      session.delete :at
      session.delete :user_id
      session.delete :service_id
      flash[:success] = 'You have been signed out!'
    end
    if flash[:facebook_canvas]
      redirect_to '/welcome'
    else
      redirect_to root_url
    end
  end

  def failure
    flash[:error] = 'There was an error at the remote authentication service. You have not been signed in.'
    redirect_to root_url
  end

end
