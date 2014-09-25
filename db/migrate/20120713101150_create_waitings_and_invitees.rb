class CreateWaitingsAndInvitees < ActiveRecord::Migration
  def change
    create_table :trips_waitings do |t|
      t.integer  :waiting_id
      t.integer  :trip_id
    end
    add_index :trips_waitings, :waiting_id
    add_index :trips_waitings, :trip_id

    create_table :trips_invitees do |t|
      t.integer  :invitee_id
      t.integer  :trip_id
    end
    add_index :trips_invitees, :invitee_id
    add_index :trips_invitees, :trip_id
  end
end
