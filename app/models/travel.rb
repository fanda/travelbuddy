# Time or Country preference
class Travel < ActiveRecord::Base
  include CountryNameHelper

  belongs_to :user
  belongs_to :trip

  attr_accessible :country, :begins, :ends, :popularity

  validate :presence_of_country_or_dates
  validates :begins, :date => {:before => :ends }, :if => :dates_present?

  # preference type scopes
  scope :country, where('country is not null')
  scope :time,    where('country is null')

  def self.not_user(id)
    where(Travel.arel_table[:user_id].not_eq(id)).where(:trip_id => nil)
  end

  def self.users(ids)
    includes(:user).where(["user_id IN (?)", ids]).where(:trip_id => nil)
  end

  def self.most_popular
    where('popularity is not null').
    order('popularity DESC').limit(AppConfig.most_popular_limit.to_i)
  end

  #
  # matching scopes - for searching within all records
  #

  def self.match_time(begins, ends)
    includes(:user).
    where(['begins <= ? and ends >= ?', ends, begins])
    # see http://c2.com/cgi/wiki?TestIfDateRangesOverlap for explanation
  end

  def self.match_country(code)
    includes(:user).where(:country => code).where(:trip_id => nil)
  end

  def self.match_users_country(travels, ids)
    countries = travels.map {|t| t.country }
    includes(:user).
    users(ids).
    where('country IN (?)', countries).
    where(:trip_id => nil)
  end

  def self.match_users_time(travels, ids)
    user_scope = includes(:user).users(ids)
    travels.map {|t|
      user_scope.where(['begins <= ? and ends >= ?', t.ends, t.begins]).where(:trip_id => nil)
    }.flatten
  end


  #
  # matching methods - searchs what matches for one object
  # = call matching scopes with object parameters
  #

  def match_time(ids)
    Travel.users(ids).match_time(self.begins, self.ends)
  end

  def match_country(ids)
    Travel.users(ids).match_country(self.country)
  end

  def self.users_countries(user_ids)
    users_countries_hash = {}
    select('user_id, country').country.
    where(["user_id in (?)", user_ids]).
    group_by(&:user_id).
    each {|u,t| users_countries_hash[u] = t.map(&:country).join(' ') }
    users_countries_hash
  rescue
    {}
  end

  # access helper
  def countryname
    country_name self.country||''
  end

  def date_range
    "#{I18n.l self.begins} - #{I18n.l self.ends}"
  end

  # date setters - save in right format
  def begins=(date)
    date = if date.blank?
      nil
    else
      Date.strptime(date, I18n.t("date.formats.default"))
    end
    super(date)
  end

  def ends=(date)
    date = if date.blank?
      nil
    else
      Date.strptime(date, I18n.t("date.formats.default"))
    end
    super(date)
  end

private

  # validation method
  def presence_of_country_or_dates
    if [self.country, self.begins, self.ends].compact.size == 0
      self.errors[:base] << "No travel preference filled"
    end
  end

  # condition for date validation - both of dates must be given
  def dates_present?
    [self.begins, self.ends].compact.size > 0
  end

end
