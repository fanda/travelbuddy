module TravelsHelper
  include CountryNameHelper
  include PostsHelper

  # do time preference value if there is
  def preference_value(index, date)
    I18n.l @preferences[index].send(date)
  rescue
    begin
      @preferences[index].send(date)||''
    rescue
      nil
    end
  end

  # time match preference helper
  def preference_options
    html = '<option value="-"></option>'
    @preferences.each_with_index do |p, i|
      html << content_tag(
        :option,"#{(i+1).ordinalize} preference",:value=>"#{p.begins}_#{p.ends}"
      )
    end
    html.html_safe
  end

  # check if continent will be checked
  def continent_checked(name)
    params[:continents].include?(name) ? 'expanded' : 'collapsed'
  rescue
    ''
  end

  # check if country will be checked
  def country_checked(code)
    @countries.include? code
  rescue
    false
  end

  # print inner of JS array for map init
  def countries_for_javascript_array
    @countries.collect {|c| "'#{c}'" }.join(',').html_safe
  rescue
    ''
  end

  # JS array with countries
  def country_matches_for_javascript_array
    @country_matches.collect {|c| "'#{c.country}'" }.uniq.join(',').html_safe
  rescue
    ''
  end

  # JS array with time prefs
  def time_matches_for_js_array(array)
    array.uniq.map {|c|"'#{c}'"}.join(',').html_safe
  rescue
    ''
  end

  def time_message(dtext, ctext)
    message = "also wants to travel #{dtext}"
    message = "#{message}, but wants to go to #{ctext}" unless ctext.blank?
    "#{message}."
  end

  def country_message(ctext, dtext)
    message = "also wants to go to #{ctext}"
    message = "#{message}, but wants to travel #{dtext}" unless dtext.blank?
    "#{message}."
  end

end
