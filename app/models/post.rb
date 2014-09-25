# Facebook posts of user
class Post < ActiveRecord::Base

  FEED  = 1
  PHOTO = 2

  belongs_to :user

  attr_accessible :facebook_id, :country, :message, :created_time, :kind, :photo

  validates :facebook_id, :uniqueness => true

  def self.friend_updates(user_id)
    includes(:user).
    where(['user_id in (select friend_id from friendships where user_id = ?)', user_id]).
    order('created_time DESC')
  end

  def self.friend_photos(user_id)
    includes(:user).
    where(:kind => PHOTO).
    where(['user_id in (select friend_id from friendships where user_id = ?)', user_id]).
    order('created_time DESC')
  end

  def self.match_countries(codes)
    includes(:user).where(["country IN (?)", codes])
  end

  def self.photos
    where(:kind => PHOTO)
  end

  def photo?
    self.kind == PHOTO
  end

end
