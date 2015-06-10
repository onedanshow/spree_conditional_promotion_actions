module Spree
  class Promotion
    module Actions
      class ConditionalAddLineItems < Spree::Promotion::Actions::ConditionalPromotionAction

        MATCH_POLICIES = %w(any all none)
        preference :match_policy, :string, default: MATCH_POLICIES.first
        preference :explanation, :string, default: "Promotional item"

        # DD: items to match to receive promotion
        has_many :promotion_action_match_line_items, foreign_key: :promotion_action_id
        accepts_nested_attributes_for :promotion_action_match_line_items, allow_destroy: true

        # DD: items to add to order
        has_many :promotion_action_line_items, -> { where type: nil }, foreign_key: :promotion_action_id
        accepts_nested_attributes_for :promotion_action_line_items, allow_destroy: true        

        # Hat tip: Brian Buchalter http://blog.endpoint.com/2013/08/buy-one-get-one-promotion-with-spree.html

        def eligible?(options = {})
          return unless order = options[:order]

          if preferred_match_policy == 'all'
            match_variants.all? {|p| order.variants.include?(p) }
          elsif preferred_match_policy == 'any'
            order.line_items.reload.any? {|li| matches_a_promo_line_item?(li)}
          else
            order.variants.none? {|p| match_variants.include?(p) }
          end
        end

        def perform_eligible_action(options={})
          return unless order = options[:order]

          promotion_action_line_items.each do |promotion_action_line_item|
            existing_line_item = find_existing_line_item(promotion_action_line_item, order)
            if existing_line_item
              existing_line_item.update_attribute(:quantity, promotion_action_line_item.quantity)
            else
              create_line_item(promotion_action_line_item, order)
            end
          end
        end

        def perform_ineligible_action(options={})
          return unless order = options[:order]
          remove_promotional_line_items(order)
        end

        private
          def matches_a_promo_line_item?(order_line_item)
            promotion_action_match_line_items.any? { |promotion_action_match_line_item|
              # if order line item is NOT a promo item itself
              !order_line_item.immutable &&
              # TEMPORARY HACK: order variant is not less than $10
              order_line_item.variant.price > 10 &&
              # and if order variant is a promo variant
              variant_is_promo_variant?(order_line_item.variant,promotion_action_match_line_item.variant) &&
              # and quantity constrant is met
              order_line_item.quantity >= promotion_action_match_line_item.quantity &&
              # and price of promo variant is not less than order variant
              promotion_action_line_items.all? {|li| order_line_item.variant.price >= li.variant.price }
            }
          end

          def match_variants
            @match_variants ||= promotion_action_match_line_items.map(&:variant).compact
          end

          def promo_variants
            @promo_variants ||= promotion_action_line_items.map(&:variant).compact
          end

          def create_line_item(promotion_action_line_item, order)
            variant = promotion_action_line_item.variant
            quantity = promotion_action_line_item.quantity

            current_quantity = order.quantity_of(variant)
            if current_quantity < quantity
              quantity_to_add = quantity - current_quantity
              new_line_item = order.line_items.new( quantity: quantity_to_add,
                                    variant: variant,
                                    immutable: true,
                                    explanation: preferred_explanation,
                                    price: 0.0 #variant.price
                                  )
              new_line_item.save
            end
          end

          def remove_promotional_line_items(order)
            # DD: replace with order.line_items.where(immutable:true).destroy_all ?
            order.line_items.each do |li|
              if is_a_promotional_line_item?(li)
                li.inventory_units.destroy_all # HACK: should be handled by Spree::OrderInventory
                li.destroy
              end
            end
          end

          def find_existing_line_item(line_item, order)
            order.line_items.find_by(variant_id: line_item.variant_id)
          end

          def is_a_promotional_line_item?(line_item)
            line_item.immutable && 
              promo_variants.any? { |promo_variant|
                variant_is_promo_variant? line_item.variant, promo_variant
              }
          end

          def variant_is_promo_variant?(v,promo_v)
            # if variants are the same or promo variant is a master that order variant is part of
            v == promo_v || (promo_v.is_master? && v.product_id == promo_v.product_id)
          end

          def product
            ::Spree::Product.find(preferred_product_id)
          end

      end
    end
  end
end
