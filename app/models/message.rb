# message in Friend updates
class Message < ActiveRecord::Base

  EARLY_CREATION = 30.minutes

  ACTIVE_COUNT = 1

  belongs_to :user

  paginates_per 20

  attr_accessible :text

  before_create :only_update_last_active_if_early_created

  after_create :deactive_lastest

  def self.only_active
    where(:active => true)
  end

  def self.my_updates
    only_active.order('id DESC')
  end


  def self.friend_updates(user_id)
    includes(:user).
    where(:active => true).
    where(['user_id in (select friend_id from friendships where user_id = ?) or user_id = ?', user_id, user_id]).
    order('id DESC')
  end

  def deactive_lastest
    user_messages = Message.where(:user_id => self.user_id)
    # let the first message be active
    return true if user_messages.size <= ACTIVE_COUNT
    # user's oldest active
    msg = user_messages.order("created_at DESC").offset(ACTIVE_COUNT).first
    return true if msg == user_messages.first
    msg.update_attribute :active, false
  end

  def only_update_last_active_if_early_created
    msg = Message.where(:active => false).where(:user_id => self.user_id).
                  order("created_at DESC").first # user's last message
    if msg and msg.created_at + EARLY_CREATION >= Time.now
      msg.text = self.text
      msg.created_at = Time.now
      msg.active = true
      msg.save
      deactive_lastest
      return false # new message will NOT be created
    end
    true
  #rescue
  #  return true # continue = create this message
  end


end
