class Event < ActiveRecord::Base
  has_event_calendar

  belongs_to :trip

  validates_presence_of :name, :start_at, :end_at
  validates :start_at, :date => {:before_or_equal_to => :end_at }

  attr_accessor :color
  attr_accessible :name, :start_at, :end_at, :color

  PREFERENCES_COLORS = ['#FF0014', '#FF641F', '#FEB835']

  def color
    @color||'#369bd7'
  end

end
