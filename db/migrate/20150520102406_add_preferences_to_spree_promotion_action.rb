class AddPreferencesToSpreePromotionAction < ActiveRecord::Migration
  def change
    unless column_exists? :preferences
      add_column :spree_promotion_actions, :preferences, :text
    end
  end
end
