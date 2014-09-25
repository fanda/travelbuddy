namespace :checkins do
  task :refresh => :environment do
    User.all.each do |user|
      user.check_and_save_new_friends_checkins
    end
  end
end
