# coding: utf-8
module ApplicationHelper
  include CountryNameHelper

  def active_nav_item?(path)
    if path == request.path
      ' class=active'
    else
      ''
    end
  end

  def facebook_picture_url(uid)
    "https://graph.facebook.com/#{uid}/picture"
  end

  def facebook_large_picture_url(uid)
    "https://graph.facebook.com/#{uid}/picture?type=large"
  end


  def facebook_profile_url(uid)
    "http://www.facebook.com/profile.php?id=#{uid}"
  end

  # helper to make a country info text
  def countries_from_facebook_user(user)
    codes = {}
    if user["hometown_location"] and user["hometown_location"]["country"]
      country = user["hometown_location"]["country"]
      code = country_code(country)
      codes[code] ||=[]
      codes[code] << "is from #{country}"
    end
    if user["current_location"] and user["current_location"]["country"]
      country = user["current_location"]["country"]
      code = country_code(country)
      codes[code] ||=[]
      codes[code] << "lives in #{country}"
    end
    codes
  end

  def invitation_message
    "#{current_user.name} #{t('invitation_text')}"
  end

  def wall_post_caption
    strip_tags "#{current_user.name} #{current_user.active_message}. #{t 'wall_post_text'}"

  end

  # flash messages HTML
  def flash_messages
    html = ''
    html += content_tag :div, :class => 'alert alert-error' do
        '<a class="close" data-dismiss="alert">×</a>'.html_safe+
        flash[:error]
    end if flash[:error]
    html += content_tag :div, :class => 'alert alert-success' do
        '<a class="close" data-dismiss="alert">×</a>'.html_safe+
        flash[:success]
    end if flash[:success]
    html += content_tag :div, :class => 'alert alert-notice' do
        '<a class="close" data-dismiss="alert">×</a>'.html_safe+
        flash[:notice]
    end if flash[:notice]
    content_tag :div, :id => 'messages' do
      html.html_safe
    end
  end

  # convert heatmap data to javascript array
  def heatmap_javascript_array(a)
    a.to_a.map {|pair| "'#{pair[0]}':#{pair[1]}"}.join(',')
  end

  # for sidebar on landing page
  def random_users_fb_ids
    min_id = User.minimum("id")
    max_id = User.maximum("id") - 100
    max_id = max_id > 0 ? max_id : min_id
    id_range = max_id - min_id + 1
    random_id = min_id + rand(id_range).to_i
    User.where("id >= #{random_id}").limit(100).collect { |u|
      u.facebook_id
    }.compact.join(',')
  end

end
