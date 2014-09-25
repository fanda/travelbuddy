require 'RMagick'
class User < ActiveRecord::Base
  include CountryNameHelper
  include PostsHelper
  include Upload

  NOT_NOTIFY  = 0
  NOTIFY_MAIL = 1  # default
  NOTIFY_WALL = 2

  has_many :services, :dependent => :delete_all
  has_many :travels,  :dependent => :delete_all
  has_many :messages, :dependent => :delete_all
  has_many :checkins, :dependent => :delete_all
  has_many :posts,    :dependent => :delete_all
  has_many :friends, :through => :friendships
  has_many :inverse_friends, :through => :inverse_friendships, :source => :user
  has_many :friendships
  has_many :inverse_friendships,
           :class_name => "Friendship", :foreign_key => "friend_id"

  has_many :attachments
  has_and_belongs_to_many :trips, :uniq => true

  accepts_nested_attributes_for :travels, :reject_if => :all_blank, :allow_destroy => true

  attr_accessible :name, :email, :uid, :travels_attributes, :preference, :hometown, :location

  alias_attribute :uid, :facebook_id

  validates :email, :uniqueness => true, :email_format => true
  validates :preference, :numericality => { :only_integer => true }

  after_create :find_friends_and_create_friendships, :make_join_application_message, :make_empty_map, :set_user_locations

  # match method - same for time and country - symbol is param
  def match(what, friends=nil)
    my_travels = self.travels.send("#{what}")
    Travel.send("match_users_#{what}", my_travels, friends||self.friend_ids)
  end

  # after getting matched travel, we make message to view
  # its dynamic method for both - country and time
  def match_messages(what, matches=nil, opt={})
    matches ||= self.match(what)
    grouped = matches.group_by(&:user_id)
    messages = self.method("messages_#{what}")
    Hash[grouped.map {|k, v| [v.first.user, messages.call(v,opt)] }]
  end

  # compute perfect matches
  def perfect_matches(time_matches=nil, country_matches=nil)
    # gets and group separated matches
    tm = (time_matches   ||self.match(:time)   ).group_by(&:user_id)
    cm = (country_matches||self.match(:country)).group_by(&:user_id)
    # 1. delete matches which are not in both time and country
    cm = cm.delete_if {|k| ! tm.key? k }
    tm = tm.delete_if {|k| ! cm.key? k }
    # 2. merge separated matches to Array accessible by friend_id
    tm.merge!(cm) {|key,t,c|  {:time => t, :country => c}  }
    # 3. change friend_id to User object for performance reason
    Hash[tm.map {|k, v| [v[:time].first.user, v] }]
  end

  def make_message(text)
    self.messages.create(text: text)
  end

  def friend_updates
    Message.friend_updates(self.id)
  end

  # makes messages for country matches
  # it is case of countries.size (count)
  # second item in returned array is string with country codes
  def messages_country(countries, opt={})
    n = AppConfig.shown_countries
    if countries.size == 1
      ctext = countries.first.countryname
    elsif countries.size == 2
      ctext = "#{countries.first.countryname} and #{countries.last.countryname}"
    elsif countries.size <= n
      ctext = countries[0..-2].map {|c| c.countryname }.join(', ')
      ctext << " and #{countries.last.countryname}"
    elsif countries.size == n + 1
      ctext = countries[0..(n-1)].map {|c| c.countryname }.join(', ')
      ctext << " and #{countries.last.countryname}"
    elsif countries.size > n
      ctext = countries[0..(n-1)].map {|c| c.countryname }.join(', ')
      alt = countries[n..-2].map  {|c| c.countryname }.join(', ')
      alt << " and #{countries.last.countryname}"
      ctext << " and <a name=\"c\" title=\"#{alt}\">#{countries.size - n} other countries</a>"
    end
    user_dates = countries.first.user.travels.time
    dtext = nil
    if user_dates.any? and opt.key?(:include_time_messages)
      dtext = self.messages_time(user_dates).first
    end
    [
      countries.empty? ? nil : ctext, # texts
      countries.map {|c| c.country }.join(' '), # countries for classes
      dtext # in case of include_time_messages
    ]
  end

  # time matches messages - for each count of given preferences
  # second item in returned array is string with begins_ends values
  # third item is array of all prefered countries of user
  def messages_time(dates, opt={})
    if dates.size == 1
      dtext = "between #{I18n.l dates.first.begins} - #{I18n.l dates.first.ends}"
    elsif dates.size == 2
      dtext = "#{I18n.l dates[0].begins} - #{I18n.l dates[0].ends}"
      dtext << " or #{I18n.l dates[1].begins} - #{I18n.l dates[1].ends}"
    elsif dates.size > 2
      dtext = dates[0..-2].map {|d| "#{I18n.l d.begins} - #{I18n.l d.ends}"}.join(', ')
      dtext << " or #{I18n.l dates.last.begins} - #{I18n.l dates.last.ends}"
    end
    user_countries = dates.first.user.travels.country
    ctext = nil
    if user_countries.any? and opt.key?(:include_country_messages)
      ctext = self.messages_country(user_countries).first
    end
    [
      dates.empty? ? nil : dtext, # text
      dates.map {|d| "#{d.begins}_#{d.ends}" }.join(' '), # dates for html classes
      user_countries.map {|t| t.country }, # have to include countries for our map
      ctext # in case of include_country_messages
    ]
  end

  # create messages - used after successful travel preferences creation
  # saved messages are used in Friend Updates
  def create_messages(persistent=true)
    countries = self.travels.country
    dates     = self.travels.time
    message = ''
    message += "wants to go to #{messages_country(countries).first}" if countries.any?
    message += " and " if message.size > 0 and dates.any?
    message += "wants to travel #{messages_time(dates).first}" if dates.any?
    if persistent and message.size > 0
      self.make_message message
    else
      message
    end
  end

  # used for wall post
  def active_message
    self.messages.only_active.order('id ASC').last.text
  rescue
    self.messages.first.text
  end

  def most_popular_countries
    self.travels.country.most_popular
  end

  # create map from svg data and upload to s3
  def map=(svg)
    svg_to_img_to_s3 "map/#{self.id}.jpg", svg
    map # return value is map, see below
  rescue
    map
  end
  # map (as image on s3) link
  def map
    t = Time.now.to_i # always load new
    "http://#{AppConfig.s3.bucket}.s3.amazonaws.com/map/#{self.id}.jpg?t=#{t}"
  end

  def notify_throught_wall?; !(self.preference & NOTIFY_WALL).zero? end
  def notify_throught_mail?; !(self.preference & NOTIFY_MAIL).zero?; end

  # when travel preferencies saved, check for perfect matches
  # and if found, send notification to friend wall feed
  def notify_perfect_matches(new_countries)
  # we cannot use perfect matches
    tm = self.match(:time).group_by(&:user_id) # we want all
    # we want only new_countries
    cm = self.match(:country).select {|m| new_countries.include?(m.country) }
    cm = cm.group_by(&:user_id)
    # two steps identical with self.perfect_matches
    cm = cm.delete_if {|k| ! tm.key? k }
    tm = tm.delete_if {|k| ! cm.key? k }
    # 2. merge separated matches to Array accessible by friend_id
    tm.merge!(cm) {|key,t,c|  {:time => t, :country => c}  }
    # 3. change friend_id to User object for performance reason
    pm = Hash[tm.map {|k, v| [v[:time].first.user, v] }]

    pm.each do |friend, travels|
      begin
        message = "#{self.name} also wants to go to"
        message = "#{message} #{self.messages_country(travels[:country]).first}"
        message = "#{message} and also wants to travel"
        message = "#{message} #{self.messages_time(travels[:time]).first}."
        if friend.notify_throught_wall?
          friend.facebook_put_feed(I18n.t('facebook.feed.perfect_caption'), message)
        elsif friend.notify_throught_mail?
          NoticeMailer.perfect_match(friend, message).deliver
        end
      rescue
        next
      end
    end
  end
  #handle_asynchronously :notify_perfect_matches

  def facebook # init Facebook Graph API
    @graph ||= Koala::Facebook::API.new(facebook_token)
  end

  def facebook_uid
    facebook_service.uid
  end

  def fql(fql) # do FQL query
    facebook.fql_query(fql)
  end

  # Post to user's Wall througth Graph API
  # done with Delayed::Job
  def facebook_put_feed(caption, description, message=nil)
    facebook.put_object("me", "feed",
      :message => message,
      :link => AppConfig.app_url,
      :description => description,
      :caption =>  caption,
      :privacy => { 'value' => 'CUSTOM', 'friends' => 'NO_FRIENDS' }
    )
  end
  #handle_asynchronously :facebook_put_feed

  def picture_url
    "https://graph.facebook.com/#{facebook_id}/picture"
  end

  def facebook_token
    facebook_service.token
  rescue
    nil
  end

  def facebook_service
    @fb_service ||= self.services.find_by_provider('facebook')
  end

  FACEBOOK_FRIENDS_WITH_LOCATIONS = lambda do |friend_facebook_ids|
    "SELECT current_location,hometown_location FROM user WHERE uid IN (#{friend_facebook_ids})"
  end

  def facebook_friends_locations(only=[])
    friends = self.friends # all friends and their facebook ids
    friend_facebook_ids = friends.collect {|f| f.facebook_id }.join(',')
    locations = self.fql( FACEBOOK_FRIENDS_WITH_LOCATIONS.call friend_facebook_ids )# insert facebook ids to FQL

    array_of_friends_and_locations = {} # init hash for return value
    friends.each_with_index do |friend, i|
      if locations[i]['current_location'] # exists? yes=>make code
        ccode = country_code(locations[i]['current_location']['country'])
      end
      if locations[i]['hometown_location'] # exists? yes=>make code
        hcode = country_code(locations[i]['hometown_location']['country'])
      end

      next unless ccode or hcode # next if no ccode and no hcode

      friends_locations = {} # init help hash
      if ccode == hcode and only.include?(ccode) # its same so prepare only one of them
        friends_locations[:current] = [ locations[i]['current_location']['country'], ccode ]
      else
        if ccode and only.include?(ccode) # prepare if is in only
          friends_locations[:current] = [ locations[i]['current_location']['country'], ccode ]
        end
        if hcode and only.include?(hcode) # prepare if is in only
          friends_locations[:hometown] = [ locations[i]['hometown_location']['country'], hcode ]
        end
      end
      next if friends_locations.empty?
      array_of_friends_and_locations[ friend] =  friends_locations
    end
    array_of_friends_and_locations # can by {}
  rescue
    return {} # fur Sicher
  end

  FQL_FRIENDS_NOT_IN_APP_WITH_INFO = 'select uid, name, current_location, hometown_location from user where uid in (select uid2 from friend where uid1=me()) and is_app_user=0 and (hometown_location <> "" or current_location <> "")'

  def facebook_friends_with_location_info_and_not_in_app
    self.fql(FQL_FRIENDS_NOT_IN_APP_WITH_INFO)
  end

  def check_and_save_new_friends_checkins
    # get from fb
    begin
      frnd_checkins = facebook.batch do |batch_api|
        self.friends.each do |friend|
          batch_api.get_connections(friend.facebook_id, 'checkins')
        end
      end
    rescue
      return false
    end
    # make Checkin
    self.friends.each_with_index do |f, i|
      checkins = frnd_checkins[i]
      next if checkins.empty?
      checkins.each do |checkin|
        begin
          db_checkin = f.checkins.create({
            :facebook_checkin_id => checkin['id'],
            :country => country_code(checkin['place']['location']['country']),
            :city => checkin['place']['location']['city'],
            :message => checkin['message'],
            :created_time => checkin['created_time']
          })
        rescue
          next
        end
      end
    end
    true
  end
  handle_asynchronously :check_and_save_new_friends_checkins

  def check_and_save_new_photo_posts
    # get from fb
    albums = self.facebook.get_connections('me', 'albums')
    countries = []
    posts = []
    # make Post if there are some new
    albums.each do |album|
      is_public = ['everyone'].include?(album['privacy'])
      # get from fb
      photos = self.facebook.get_connections(album['id'], 'photos')
      next if photos.empty?
      # each photo is saved as Post of kind PHOTO
      photos.each do |photo|
        if photo['place'] and photo['place']['location']
          country_name = photo['place']['location']['country'] || photo['place']['name']
          if country_name and code = country_code(country_name)
            image = photo['images'].select {|i| i['width'] == 180 }
            begin
              db_post = self.posts.create!({
                :kind => Post::PHOTO,
                :facebook_id => photo['id'],
                :country => code,
                :message => album['name'],
                :created_time => photo['created_time'],
                :photo => image.any? ? image.first['source'] : nil
              })
              unless is_public
                countries << code unless countries.include?(code)
                posts << db_post
              end
            rescue
              next
            end
          end
        end
      end
    end
    if posts.any?
      # similar to messages_country, TODO this into method
      n = AppConfig.shown_countries
      if countries.size == 1
        ctext = country_name countries.first
      elsif countries.size == 2
        ctext = "#{country_name countries.first} and #{country_name countries.last}"
      elsif countries.size <= n
        ctext = countries[0..-2].map {|c| country_name c }.join(', ')
        ctext << " and #{country_name countries.last}"
      elsif countries.size == n + 1
        ctext = countries[0..(n-1)].map {|c| country_name c }.join(', ')
        ctext << " and #{country_name countries.last}"
      elsif countries.size > n
        ctext = countries[0..(n-1)].map {|c| country_name c }.join(', ')
        alt = countries[n..-2].map  {|c| country_name c }.join(', ')
        alt << " and #{country_name countries.last}"
        ctext << " and <a name=\"c\" title=\"#{alt}\">#{countries.size - n} other countries</a>"
      end
      make_message("has new photos from #{ctext}. #{scrollable_photos(posts[0..3], self.facebook_id)}")
    end
    true
  rescue
    false
  end
  handle_asynchronously :check_and_save_new_photo_posts

  def check_and_save_new_feed_posts
    posts = self.facebook.get_connections('me', 'posts')
    return true if posts.empty?
    posts.each do |post|
      countries = []
      if post['place'] and post['place']['location']
        if post['place']['location']['country']
          code = country_code(post['place']['location']['country'])
          next if countries.include?(code)
          countries << code
          begin
            db_post = self.posts.create({
              :kind => Post::FEED,
              :facebook_id => post['id'],
              :country => code,
              :created_time => post['created_time']
            })
          rescue
            next
          end
        end
      end
    end
    true
  rescue
    false
  end
  handle_asynchronously :check_and_save_new_feed_posts


  def matched_friends_checkins(countries)
    Checkin.friend_updates(self.id).match_countries(countries)
  end

  def matched_friends_posts
    Post.friend_updates(self.id)
  end

  def matched_friends_photos(countries)
    grouped = Post.friend_photos(self.id).match_countries(countries).group_by(&:user_id)
    Hash[grouped.map {|k, v| [v.first.user, v.group_by(&:country)] }]
  end

  def friends_with_locations
    {
      :hometown => self.friends.where(User.arel_table['hometown'].not_eq('')).group_by(&:hometown),
      :location => self.friends.where(User.arel_table['location'].not_eq('')).group_by(&:location)
    }
  end

  FACEBOOK_MY_LOCATIONS = "SELECT current_location,hometown_location FROM user WHERE uid = me()"

  # after user creation
  def set_user_locations
    locations = self.fql( FACEBOOK_MY_LOCATIONS ) # get my locations
    return true if locations.empty?
    if locations.first['current_location'] # exists? yes => save
      self.location = country_code(locations.first['current_location']['country'])
    end
    if locations.first['hometown_location'] # exists? yes => save
      self.hometown = country_code(locations.first['hometown_location']['country'])
    end
    self.save
  end
  handle_asynchronously :set_user_locations

  #  User.all.each {|u| begin; u.set_user_locations; rescue; next; end }

private

  FQL_FRIENDS_UIDS = 'select uid from user where uid in (select uid2 from friend where uid1=me()) and is_app_user=1'

  # after user creation - connects all existing friends
  def find_friends_and_create_friendships
    # search friends IDS with service API
    services.each do |s|
      sid = s.uid # user's id in service
      case s.provider
        when 'facebook'
          friends_uids = self.fql(FQL_FRIENDS_UIDS).map {|r|r['uid'].to_s}
        else
          friends_uids = []
      end
      # find that friends in DB
      users = User.select('id').where("#{s.provider}_id" => friends_uids)
      # join users by import ids to join table - fastest way
      users.map! {|u| [[u.id, self.id],[self.id,u.id]] }
      Friendship.import [:user_id,:friend_id],users.flatten(1),:validate=>false
    end
    true
  end

  # after user creation
  def make_join_application_message
    make_message('joined Travel Buddy')
  end

  # after user creation
  def make_empty_map
    self.map = File.read("#{Rails.root}/lib/empty.svg")
  end

end
