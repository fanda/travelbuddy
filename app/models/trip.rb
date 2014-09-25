
class Trip < ActiveRecord::Base
  include Upload

  # regular users in the group
  has_and_belongs_to_many :users, :uniq => true
  # users not approved to be in the group
  has_and_belongs_to_many :waitings, :uniq => true, :class_name => 'User', :association_foreign_key => "waiting_id", :join_table => 'trips_waitings'
  # users not approved to be in the group
  has_and_belongs_to_many :invitees, :uniq => true, :class_name => 'User', :association_foreign_key => "invitee_id", :join_table => 'trips_invitees'

  has_many :travels

  has_many :events
  has_many :attachments

  attr_accessible :name, :about, :travels_attributes

  validates_presence_of :name

  accepts_nested_attributes_for :travels, :reject_if => :all_blank, :allow_destroy => true

  # create map from svg data and upload to s3
  def map=(svg)
    svg_to_img_to_s3 "tripmap/#{self.id}.jpg", svg
    map # return value is map, see below
#  rescue
#    map
  end
  # map (as image on s3) link
  def map
    t = Time.now.to_i # always load new
    "http://#{AppConfig.s3.bucket}.s3.amazonaws.com/tripmap/#{self.id}.jpg?t=#{t}"
  end


  def pals_of(user)
    self.users - [user]
  end

  def invite_users_with_facebook_ids(uids)
    users = User.where(:facebook_id => uids).select('distinct users.*')
    users.each do |user|
      next if self.users.include?(user) or self.invitees.include?(user) or self.waitings.include?(user)
      self.invitees << user
      # send notification to this user
      if user.notify_throught_wall?
        message = "#{I18n.t('invitation_feed_message') } #{self.name}"
        user.facebook_put_feed(I18n.t('invitation_mail_subject'), message)
      elsif user.notify_throught_mail?
        NoticeMailer.delay.trip_invitation(user, self)
      end
    end
    true
  end

  def save_request(user)
    return false if self.users.include?(user) or self.invitees.include?(user) or self.waitings.include?(user)
    # save him in DB
    self.waitings << user
    # send notification to all group members
    self.users.each do |user|
      if user.notify_throught_wall?
        message = "#{I18n.t('request_feed_message') } #{self.name}"
        user.facebook_put_feed(I18n.t('request_mail_subject'), message)
      elsif user.notify_throught_mail?
        NoticeMailer.delay.trip_request(user, self)
      end
    end
    true
  end

  # it is case of countries.size (count)
  def message_country
    countries = self.travels.country
    return nil if countries.blank?
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
    ctext
  end

end
