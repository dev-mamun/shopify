class HomeController < ApplicationController
 def create
  load('/shopify.rb')
end
 def index
shop_name = "brainverb"
admin_email = "arif@brainverb.com"
admin_password = "brainverb"
coupon_name = "MAMUN"
discount_type = "fixed_amount"
discount_value = "450"
applies_to_resource = ""
usage_limit = "1"

shopify = Shopify.new(shop_name,admin_email,admin_password)
is_loged_in = shopify.login
if(is_loged_in[:success])
  is_promotion = shopify.get_promotion_page
  if(is_promotion[:success])
    is_coupon = shopify.create_discount(coupon_name, discount_type, discount_value, applies_to_resource, usage_limit)
   
    render :json => is_coupon
  end
end
end
end

