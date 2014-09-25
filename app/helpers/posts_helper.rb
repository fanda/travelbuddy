module PostsHelper

  # jquery.tools library helper
  # horizontal scrollable content INIT
  def scrollable_photos(posts, profile_id=nil)
    html = '<div class="photos-messages"><div class="items">'
    posts.each do |post|
      if post.photo
        html += "<img src=\"#{post.photo}\" class=\"matched_pic\" />"
      end
    end
    html += '</div></div>'
    if profile_id
      html += "<a href=\"http://www.facebook.com/profile.php?id=#{profile_id}&sk=photos\" class=\"goto\" target=\"_blank\"></a>"
    else
      html += '<a href="#" class="prev browse left" onclick="return false;"></a>'
      html += '<a href="#" class="browse next right" onclick="return false;"></a>'
    end
    html
  end

end
