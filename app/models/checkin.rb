# Facebook checkins of user
class Checkin < ActiveRecord::Base

  belongs_to :user

  attr_accessible :facebook_checkin_id,:country,:city,:message,:created_time

  validates :facebook_checkin_id, :uniqueness => true

  def self.friend_updates(user_id)
    includes(:user).
    where(['user_id in (select friend_id from friendships where user_id = ?)', user_id]).
    order('id DESC')
  end

  def self.match_countries(codes)
    includes(:user).where(["country IN (?)", codes])
  end

end
