module SpreeConditionalPromotionActions
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_conditional_promotion_actions'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    initializer "spree.register.promotion_action" do |app|
      # rules
      app.config.spree.promotions.rules << Spree::Promotion::Rules::UseConditionalAction
      # actions
      app.config.spree.promotions.actions << Spree::Promotion::Actions::ConditionalAddLineItemAdjustments
      app.config.spree.promotions.actions << Spree::Promotion::Actions::ConditionalAddLineItems
      app.config.spree.promotions.actions << Spree::Promotion::Actions::ConditionalFreeShipping
      # calculators
      app.config.spree.calculators.add_class('promotion_actions_conditional_add_line_item_adjustments')
      app.config.spree.calculators.promotion_actions_conditional_add_line_item_adjustments = [
        Spree::Calculator::PercentOnLineItem
      ]
    end

    config.to_prepare &method(:activate).to_proc
  end
end
