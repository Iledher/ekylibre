# == Schema Information
#
# Table name: inventory_lines
#
#  company_id         :integer       not null
#  created_at         :datetime      not null
#  creator_id         :integer       
#  id                 :integer       not null, primary key
#  inventory_id       :integer       not null
#  location_id        :integer       not null
#  lock_version       :integer       default(0), not null
#  product_id         :integer       not null
#  theoric_quantity   :decimal(16, 2 not null
#  updated_at         :datetime      not null
#  updater_id         :integer       
#  validated_quantity :decimal(16, 2 not null
#

class InventoryLine < ActiveRecord::Base


  def after_create
    puts self.validated_quantity.to_s+"   "+self.theoric_quantity.to_s+"    lllllllll"
    if self.validated_quantity != self.theoric_quantity
      rslt =  (self.validated_quantity.to_f != self.theoric_quantity.to_f)
      puts rslt
      input = self.validated_quantity < self.theoric_quantity ? false : true
      #raise Exception.new self.theoric_quantity.to_s+" "+self.validated_quantity.to_s+"   "+input.to_s
      if input
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.validated_quantity - self.theoric_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id, :generated=>true)
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.validated_quantity - self.theoric_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id ,:generated=>true)
      else
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.theoric_quantity - self.validated_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>true ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id ,:generated=>true)
        StockMove.create!(:name=>tc('inventory')+" "+Date.today.to_s, :quantity=>(self.theoric_quantity - self.validated_quantity) , :location_id=>self.location_id, :product_id=>self.product_id, :planned_on=>Date.today, :moved_on=>Date.today, :company_id=>self.company_id, :virtual=>false ,:input=>input, :origin_type=>InventoryLine.to_s, :origin_id=>self.id ,:generated=>true)
      end
    end
  end
  
end
