# To change this template, choose Tools | Templates
# and open the template in the editor.

class Shopify
  require 'rubygems'
  require 'cgi'
  require 'mechanize'
  require 'json'
  require 'nokogiri'
  require "StringUtils.rb"
  #require "/home/beaudrip/public_html/shopifyruby/brainverb/StringUtils.rb"
  require "base64"
  
  def initialize(shop,user,pass)
    @shop = shop
    @user = user
    @pass = pass
    @http = Mechanize.new
    @string_utils = StringUtils.new 
    @http.user_agent = "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
    @http.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @base_url = "https://#{@shop}.myshopify.com/"
    @login_url = "#{@base_url}admin/auth/login"
    @promotions_url = "#{@base_url}admin/marketing"
    @discount_create_url = "#{@base_url}admin/discounts"
    @output_string = ""
    @authenticity_token = ""
    
    #@file_path = "/home/beaudrip/public_html/shopifyruby/brainverb/"
    @file_path = "D:\\wamp\\www\\shopify\\brainverb\\"
    
    @file_name = "discountassetjson.txt"
    
    #@upload_url = "http://beautydrip.com/shopifyruby/brainverb/uploaddiscount.php?file="
    @upload_url = "http://localhost/shopify/brainverb/uploaddiscount.php?file="
  end
  
  def login
    result=-2
    begin
      @output_string += "Start: Fetching login page \n"
      @output_string += "Shope: #{@shop} \n"
      @output_string += "Email: #{@user} \n"
      @output_string += "Base Url: #{@base_url} \n"
      @output_string += "Login Url: #{@login_url} \n"
            
      login_page = @http.get("#{@login_url}")
      login_form = login_page.form
      login_form.login = @user
      login_form.password = @pass
      
      @output_string += "Submit: Submitting login form \n"
      @authenticity_token = login_form.authenticity_token
      login_result = @http.submit(login_form, login_form.button)
      loggedin = login_result.body.match(">Logout<")
      if loggedin!=nil
        result=1       # Login success
      else
        doc = Nokogiri::HTML(login_result.body)
        error = doc.at('div#system_error p')
        @output_string += "Login: Fail \n"
        @output_string += "Error: #{error} \n"
        result=0      # Login Fail
      end
      rescue
        result=-1        # Server Down
    end
    if(result==-1)
        return {:success => false, :msg => "Server Down"}    #server is down
    elsif(result==0)
        return {:success => false, :msg => error}    #wrong login
    elsif(result==1)
        return {:success => true, :msg => "Login Successfull"}                       #success
    else
        return {:success => false, :msg => "Code Chenged"}   # code changed
    end 
  end
  
  def get_promotion_page
      @output_string += "Start: Fetching Promotion page \n"
    begin
      promotion_page = @http.get("#{@promotions_url}")
      is_discount = promotion_page.body.match(">Discount codes<")
      if is_discount==nil
         return {:success => false, :msg => "Cound not found discount code option"}
      else
        @string_utils.container = promotion_page.body
        @authenticity_token = @string_utils.parseAllValueBetween("_authenticity_token = '", "';")
        @string_utils.container = @string_utils.substring(@string_utils.indexof("<div id='discount_table'>")+"<div id='discount_table'>".length)
        table = @string_utils.substring(0, @string_utils.indexof('<div class="sst ssb">'))
        return {:success => true, :msg => table}
      end 
    end
  end
  
  def parse_discount(table)
    discount_codes = []
    @string_utils.container = table
    @string_utils.container = @string_utils.substring(@string_utils.indexof("<tbody>")+"<tbody>".length)
    tbody = @string_utils.substring(0, @string_utils.indexof('</tbody>'))
    rows = tbody.split("</tr>")
   
    for i in 0..rows.length-2
        @string_utils.container = rows[i]
        @string_utils.container = @string_utils.substring(@string_utils.indexof("<tr id=\"discount-")+"<tr id=\"discount-".length)
        id = @string_utils.substring(0,@string_utils.indexof("\""))
        col = rows[i].split("</td>")
        @string_utils.container = col[0]
        title = @string_utils.parseAllValueBetween("<strong>","</strong>")
        @string_utils.container = col[1]
        discount = @string_utils.parseAllValueBetween("<strong>","</strong>")
        use_remain = col[2].split("</li>")
        @string_utils.container = use_remain[0]
        used = @string_utils.parseAllValueBetween("<li>Used","times")
        @string_utils.container = use_remain[1]
        remain = @string_utils.parseAllValueBetween("<li>"," ")
        disable = @base_url+"admin/discounts/"+id+"/disable?page=1"
        delete = @base_url+"admin/discounts/"+id
        discount_codes[i] ={:id=>id,:auth_token=>@authenticity_token,:title => title,:discount=>discount,:used=>used,:remain=>remain,:disable_url=>disable,:delete_url=>delete}
    end
    return discount_codes
  end
  
  def delete_discount_code(items)
    deleted = []
    is_deleted = false
    for i in 0..items.length-1
      id = items[i][:id]
      authtoken = items[i][:auth_token]
      remain = items[i][:remain]
      if remain == '0'
        url = items[i][:delete_url]
        is_delete = delete_discount(id, authtoken,url)
        if(is_delete[:status])
          coupon_name = random_string()
          discount_type = "percentage"
          discount_value = items[i][:discount]
          applies_to_resource = ""
          usage_limit = "1"
          is_create = create_discount(coupon_name, discount_type, discount_value, applies_to_resource, usage_limit)
          deleted[i] = {:status=>"deleted",:delete=>is_delete,:create=>is_create}
          is_deleted = true
        else
          deleted[i] = {:status=>"Not Delete",:delete=>is_delete}
        end
      else
        deleted[i] = {:id=>id,:remain=>remain,:status=>'Not delete'}
      end
    end
    if(is_deleted)
      deleted = {:success=>true,:response=>deleted}
    else
      deleted = {:success=>false,:response=>deleted}
    end
    return deleted
  end
  
  def delete_discount(id,authtoken='',url='')
    @output_string += "Start: Fetching Coupon page for Delete \n"
    result = []
    begin
      if authtoken == ""
        authtoken = @authenticity_token
      end
      if url == ''
        url = "#{@base_url}admin/discounts/#{id}"
      end
      if id !=''    
        ajax_headers = { 'X-Requested-With' => 'XMLHttpRequest'}
        params = {'authenticity_token' => authtoken,'_method'=>'delete'}
        begin
          response = @http.post(url, params, ajax_headers)
          @string_utils.container = response.body 
          @output_string += "#{response.body} \n"
          is_delete = @string_utils.indexof("Messenger.error(")
          if is_delete == nil
            result = {:id=>id,:status=>true,:msg=>@string_utils.parseAllValueBetween("notice(\"","\");")}
          else
            result = {:id=>id,:status=>false,:msg=>@string_utils.parseAllValueBetween("error(\"","\");")}
          end
        rescue => e
          @output_string += "Error:#{e.message} \n"
          @output_string += "Error Backtrace:#{e.backtrace} \n"
          @output_string += "Error Response#{e.page.body} \n"
          result = {:id=>id,:status=>false,:msg=>"Coupon does not exist."}
        end          
      else
        result = {:id=>id,:status=>false,:msg=>"Coupon ID can't be empty"}
      end
      return result
    end
  end
  
  def create_discount(coupon_name,discount_type,discount_value,applies_to_resource,usage_limit)
   @output_string += "Start: Fetching Coupon page for create \n"
   ajax_headers = { 'X-Requested-With' => 'XMLHttpRequest'}
   result = []
   begin
     params = {
          'authenticity_token' => @authenticity_token,
          'utf8'=>'%E2%9C%93',
          'discount[code]'=>coupon_name.to_s,
          'discount[discount_type]'=>discount_type.to_s,
          'discount[value]'=>discount_value.to_s,
          'discount[applies_to_resource]'=>applies_to_resource.to_s,
          'discount[minimum_order_amount]'=>'0.00',
          'discount[starts_at]'=>'',
          'discount[ends_at]'=>'',
          'discount[usage_limit]'=>usage_limit.to_s,
          'commit'=>'Create discount',
          'page'=>'1'
          }
      response = @http.post(@discount_create_url, params, ajax_headers)
      @output_string += "#{response.body} \n"
      @string_utils.container = response.body
      is_created = @string_utils.indexof("Messenger.error(")
      if is_created != nil
        result = {:status=>false,:msg=>@string_utils.parseAllValueBetween("error(\"","\");"),:coupon=>coupon_name.to_s,:discount_value=>discount_value.to_s}
      else
        result = {:status=>true,:msg=>@string_utils.parseAllValueBetween("notice(\"",";\");"),:coupon=>coupon_name.to_s,:discount_value=>discount_value.to_s}
      end
   rescue => e
      @output_string += "Error:#{e.message} \n"
      @output_string += "Error Backtrace:#{e.backtrace} \n"
      result = {:id=>id,:status=>false,:msg=>"Coupon does not create."}
   end
     return result
  end
  
  def print_debug
    puts @output_string
  end
  
  def random_string(length=8)
    return ('A'..'Z').sort_by {rand}[0,length].join
  end
  
  def create_json(coupon_array=[])
    if coupon_array.empty?
      is_promotion = get_promotion_page
      coupon_array = parse_discount(is_promotion[:msg])
    end
    
    if !coupon_array.empty?
      json_str = ""
      i = 0
      while i < coupon_array.size do
        create = coupon_array[i]
        coupon = create[:title].to_s.gsub(/\s+/, "")
        discount_value = create[:discount].to_s.gsub(/\s+/, "")
        id = create[:id].to_s.gsub(/\s+/, "")
        if discount_value.eql?("30.0%")
            qty = "4"
        elsif discount_value.eql?("20.0%") 
            qty = "3"
        elsif discount_value.eql?("10.0%")
            qty = "2"
        end
        if json_str.eql?("")
          json_str = '{"id":"'+id+'","dcode":"'+coupon+'","qty":"'+qty+'","value":"'+discount_value+'"}'
        else
          json_str += ',{"id":"'+id+'","dcode":"'+coupon+'","qty":"'+qty+'","value":"'+discount_value+'"}'
        end
        i+=1 
      end
      json_str = "["+json_str+"]"
      filename = write_file(json_str)
      upload_to_shopify(filename)
    end
  end
  
  def delete_coupon_from_json
    filename = @file_path+"delete_coupon.json"
    response = ""
    is_deleted = false
    if File.exist?(filename)
      file = File.open(filename,'r')
      content = file.read
      file.close
      coupons = JSON.parse(content)
      unless coupons.size == 0
        i = 0 
        while i < coupons.size do
            id = coupons[i]['coupon_id']
            discount_value = coupons[i]['discount_value']
            is_delete = delete_discount(id)
            if(is_delete[:status])
              coupon_name = random_string()
              discount_type = "percentage"
              discount_value = discount_value
              applies_to_resource = ""
              usage_limit = "1"
              is_create = create_discount(coupon_name, discount_type, discount_value, applies_to_resource, usage_limit)
              is_deleted = true
            end
            i+=1
         end
         if is_deleted
           response = {:status=>true,:msg=>"Coupon deleted."}
         else
           response = {:status=>false,:msg=>"Coupon not found for delete."}
         end
      else
        response = {:status=>false,:msg=>"File is empty."}
      end
      delete = File.unlink(filename)
    else
      response = {:status=>false,:msg=>"File not found."}
    end
    return response
  end
  
  def upload_to_shopify(filename)
    @upload_url +=filename
    response = @http.get(@upload_url)
    return response.body
  end
  
  def write_file(content)
    @file_name = @file_path+@file_name
    if File.exist?(@file_name)
      delete = File.unlink(@file_name)
    end
    f = File.new(@file_name,"w")
    f.write(content)
    f.close
    return @file_name
  end
  
end
