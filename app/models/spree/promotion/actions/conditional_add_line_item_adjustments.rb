module Spree
  class Promotion
    module Actions
      class ConditionalAddLineItemAdjustments < Spree::Promotion::Actions::ConditionalPromotionAction
        include Spree::CalculatedAdjustments
        has_many :adjustments, as: :source

        before_validation :ensure_action_has_calculator
        before_destroy :deals_with_adjustments

        preference :quantity, :integer, default: 100
        preference :product_id, :integer

        # TODO: Much duplicated code here. Delegate relevant methods to the non-conditional version?
        # TODO: move shared eligible? to abstract class for actions conditional on order quantity

        def eligible?(options = {})
          return unless order = options[:order]
          quantity_ordered = product.variants_including_master.inject(0) do |sum, v|
            sum + order.quantity_of(v)
          end
          quantity_ordered >= preferred_quantity
        end

        def perform_eligible_action(options={})
          return unless order = options[:order]
          result = false
          order.line_items.where("id NOT IN (?)", already_adjusted_line_item_ids).find_each do |line_item|
            current_result = self.create_adjustment(line_item, order)
            result ||= current_result
          end
          return result

        end

        def perform_ineligible_action(options={})
          return unless order = options[:order]
          result = false
          order.line_items.find(already_adjusted_line_item_ids) do |line_item|
            current_result = self.remove_adjustment(line_item)
            result ||= current_result
          end
          return result
        end

        def create_adjustment(adjustable, order)
          amount = self.compute_amount(adjustable)
          return if amount == 0
          return unless preferred_product_id == adjustable.product.id
          self.adjustments.create!(
            amount: amount,
            adjustable: adjustable,
            order: order,
            label: "#{Spree.t(:promotion)} (#{promotion.name})",
          )
          true
        end

        def remove_adjustment(adjustable)
          adjustable.adjustments.where(source_id: self.id).destroy_all
        end

        # Ensure a negative amount which does not exceed the sum of the order's
        # item_total and ship_total
        def compute_amount(adjustable)
          amount = self.calculator.compute(adjustable).to_f.abs
          [adjustable.total, amount].min * -1
        end

        private
          # Find only the line items which have not already been adjusted by this promotion
          # HACK: Need to use [0] because `pluck` may return an empty array, which AR helpfully
          # coverts to meaning NOT IN (NULL) and the DB isn't happy about that.
          def already_adjusted_line_item_ids
            [0] + self.adjustments.pluck(:adjustable_id)
          end

          # Tells us if there if the specified promotion is already associated with the line item
          # regardless of whether or not its currently eligible. Useful because generally
          # you would only want a promotion action to apply to order no more than once.
          #
          # Receives an adjustment +source+ (here a PromotionAction object) and tells
          # if the order has adjustments from that already
          def promotion_credit_exists?(adjustable)
            self.adjustments.where(:adjustable_id => adjustable.id).exists?
          end

          def ensure_action_has_calculator
            return if self.calculator
            self.calculator = ::Spree::Calculator::PercentOnLineItem.new
          end

          def deals_with_adjustments
            adjustment_scope = self.adjustments.joins("LEFT OUTER JOIN spree_orders ON spree_orders.id = spree_adjustments.adjustable_id")
            # For incomplete orders, remove the adjustment completely.
            adjustment_scope.where("spree_orders.completed_at IS NULL").readonly(false).destroy_all

            # For complete orders, the source will be invalid.
            # Therefore we nullify the source_id, leaving the adjustment in place.
            # This would mean that the order's total is not altered at all.
            adjustment_scope.where("spree_orders.completed_at IS NOT NULL").update_all("source_id = NULL")
          end

          def product
            ::Spree::Product.find(preferred_product_id)
          end


      end
    end
  end
end