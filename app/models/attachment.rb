class Attachment < ActiveRecord::Base

  belongs_to :user
  belongs_to :trip

  has_attached_file :file,
    :storage => :s3, :bucket => AppConfig.s3.bucket,
    :s3_credentials => {
      :access_key_id => AppConfig.s3.access_key_id,
      :secret_access_key => AppConfig.s3.secret_access_key
    }

  validates_attachment_presence :file
  #validates_presence_of :name

  attr_accessible :file, :name

  after_create :send_notifications
  before_destroy 'self.file.destroy'

  def send_notifications
    self.trip.users.each do |user|
      NoticeMailer.new_trip_file(user, self)
    end
  end

end
