module CountryNameHelper

  def country_name(code)
    CountryIsoTranslater.translate_iso3166_alpha2_to_name(code.upcase)
  rescue
    nil
  end

  def country_code(identifier)
    CountryIsoTranslater.translate_iso3166_name_to_alpha2(identifier).downcase
  rescue
    nil
  end

end
