require 'RMagick'
require 'aws/s3'

module Upload
  def svg_to_img_to_s3(path, svg)
    tmp = "#{Rails.root}/tmp/#{path.sub('/','_')}" # heroku temp file, type must be appended
    File.open("#{tmp}.svg", 'w') {|f| f.write(svg) } # create image file from svg
    system("convert -background #ffffff -quality 70 #{tmp}.svg #{tmp}.jpg") # svg -> jpg
    ::AWS::S3::Base.establish_connection!( # s3 connection
      :access_key_id     => AppConfig.s3.access_key_id,
      :secret_access_key => AppConfig.s3.secret_access_key
    )
    ::AWS::S3::S3Object.store(
        path, # filename on s3
        open("#{tmp}.jpg"),   # out temp file
        AppConfig.s3.bucket,  # bucked name
        :access => :public_read # acl
    );
  end
end
