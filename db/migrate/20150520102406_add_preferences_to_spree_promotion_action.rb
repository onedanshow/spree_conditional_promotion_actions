class AddPreferencesToSpreePromotionAction < ActiveRecord::Migration
  def change
    unless column_exists? :spree_promotion_actions, :preferences
      add_column :spree_promotion_actions, :preferences, :text
    end
  end
end
