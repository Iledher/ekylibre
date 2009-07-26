# == Schema Information
#
# Table name: productions
#
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  location_id  :integer       not null
#  lock_version :integer       default(0), not null
#  moved_on     :date          not null
#  planned_on   :date          not null
#  product_id   :integer       not null
#  quantity     :decimal(16, 2 default(0.0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Production < ActiveRecord::Base

  attr_readonly :company_id, :product_id
  belongs_to :company
  belongs_to :product
  belongs_to :location, :class_name=>StockLocation.to_s

  def before_validation
    self.planned_on = Date.today
    self.moved_on = Date.today
    stock_locations = StockLocation.find_all_by_company_id(self.company_id)
    self.location_id = stock_locations[0].id if stock_locations.size == 1 and self.location_id.nil?
    #raise Exception.new
  end

  def validate
    errors.add_to_base(tc(:stock_location_can_receive_product, :location=>self.location.name, :product=>self.product.name, :contained_product=>self.location.product.name)) unless self.location.can_receive(self.product_id)
  end

 
  def before_update
    old_real_move = StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :product_id=>self.product_id, :input=>true, :virtual=>false})
    old_virtual_move = StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :product_id=>self.product_id, :input=>true, :virtual=>true})
    old_real_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id)
    old_virtual_move.update_attributes!(:quantity=>self.quantity, :location_id=>self.location_id)
  end


  def move_stocks(params={}, update=nil)
    if !params.empty?
      for component in self.product.components
        for p in params[component.id.to_s]
          if p[1].to_d > 0
            virtual_move = StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :input=>false, :location_id=>p[0] , :product_id=>component.component_id, :virtual=>true})
            real_move =  StockMove.find(:first, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id, :input=>false, :location_id=>p[0] , :product_id=>component.component_id, :virtual=>false})
            if virtual_move.nil?
              StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :location_id=>p[0], :product_id=>component.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>false, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
              StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>p[1], :location_id=>p[0], :product_id=>component.component_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>false, :input=>false, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
            else
              real_move.update_attributes(:quantity=>p[1], :location_id=>p[0])
              virtual_move.update_attributes(:quantity=>p[1], :location_id=>p[0])
            end
          end
        end
      end
    end  
    if update.nil?
      StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>true, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
      StockMove.create!(:name=>tc('production')+" "+self.id.to_s, :quantity=>self.quantity, :location_id=>self.location_id, :product_id=>self.product_id, :company_id=>self.company_id, :planned_on=>Date.today, :moved_on=>Date.today, :virtual=>false, :input=>true, :origin_type=>Production.to_s, :origin_id=>self.id, :generated=>true)
    end
  end

  def before_destroy 
    stocks_moves = StockMove.find(:all, :conditions=>{:company_id=>self.company_id, :origin_type=>Production.to_s, :origin_id=>self.id})
    for stocks_move in stocks_moves
      stocks_move.destroy
    end
  end

  
end
