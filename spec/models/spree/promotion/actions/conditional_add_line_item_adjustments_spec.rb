require 'spec_helper'

describe Spree::Promotion::Actions::ConditionalAddLineItemAdjustments do
  describe "An ConditionalAddLineItemAdjustments action" do

    before do
      # Assume a promotion where customers get a free mug when their order has at least twenty shirts
      @shirt = create(:variant, price: 100)
      @mug = create(:variant)

      @action = create(:add_or_remove_line_item_adjustments)
      @action.preferred_product_id = @shirt.product.id
      @action.preferred_quantity = 20
      @action.calculator.preferred_percent = 25
      @action.save

      @order = create(:order)
    end

    it "not allow an immutable line item quantity to be changed" #move to line items test

    describe "#eligible?" do
      it "be eligible when the quantity is more than required" do
        @order.contents.add(@shirt, 21)
        assert @action.eligible?(order: @order)
      end
      it "be eligible when the quantity is exactly the required" do
        @order.contents.add(@shirt, 20)
        assert @action.eligible?(order: @order)
      end
      it "be not be eligible when the quantity is too low" do
        @order.contents.add(@shirt, 19)
        assert !@action.eligible?(order: @order)
      end
    end

    describe "when the order is eligible" do
      before do
        @order.contents.add(@shirt, 20)
      end

      it "apply adjustment to the product" do
        assert_equal 1, @order.line_item_adjustments.count
        assert_equal -0.25 * @order.item_total, @order.adjustment_total
      end
      it "not apply a adjustment to the same product" do
        @order.contents.add(@shirt, 10)
        assert_equal 1, @order.line_item_adjustments.count
        assert_equal -0.25 * @order.item_total, @order.adjustment_total
      end
      it "not apply adjustment to a different product" do
        @order.contents.add(@mug, 1)
        assert_equal 1, @order.line_item_adjustments.count
        assert_equal -0.25 * @order.find_line_item_by_variant(@shirt).amount, @order.adjustment_total
      end
      it "remove adjustment when order subsequently becomes ineligible" do
        @order.contents.remove(@shirt, 10)
        assert_equal 0, @order.line_item_adjustments.count
      end
    end

    describe "when the order is ineligible" do
      before do
        @order.contents.add(@shirt, 19)
      end
      it "not have an adjustment" do
        @action.perform({order: @order})
        assert_equal 0, @order.line_item_adjustments.count
      end
    end

  end
end