# coding: utf-8
class NoticeMailer < ActionMailer::Base
  default :from => AppConfig.email
  add_template_helper(ApplicationHelper)
  helper ActionView::Helpers::UrlHelper

  def perfect_match(user, message)
    @user = user
    @message = message
    mail(
      :to => user.email,
      :subject => I18n.t('facebook.feed.perfect_caption')) do |format|
        format.text
    end
  end

  def trip_invitation(user, trip)
    default_url_options[:host] = AppConfig.app_url
    @user = user
    @trip = trip
    mail(
      :to => user.email,
      :subject => I18n.t('invitation_mail_subject')) do |format|
        format.text
    end
  end

  def trip_request(user, trip)
    default_url_options[:host] = AppConfig.app_url
    @user = user
    @trip = trip
    mail(
      :to => user.email,
      :subject => I18n.t('request_mail_subject')) do |format|
        format.text
    end
  end

  def new_trip_file(user, file)
    default_url_options[:host] = AppConfig.app_url
    @user = user
    @trip = file.trip
    @file = file
    mail(
      :to => user.email,
      :subject => 'New file uploaded on My Travel Buddy') do |format|
        format.text
    end
  end

end
