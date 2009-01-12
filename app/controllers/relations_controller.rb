class RelationsController < ApplicationController

  def index
    @entity = Entity.new
    @company = @current_company
    @entities = @company.entities
  end

  dyta(:entities, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :code
    t.column :full_name
    t.column :active
    t.action :entities_display, :action=>:entities_display
    t.action :entities_update, :image=>:update
    t.action :entities_delete, :image=>:delete, :method=>:post, :confirm=>:sure
  end

  def entities
    entities_list params
  end

  def entities_search
  end

  dyta(:contacts, :conditions=>{:company_id=>['@current_company.id'], :entity_id=>['session[:current_entity]']}) do |t|
    t.column :active
    t.column :default
    t.column :mobile
    t.column :fax
    t.action :entities_contact_update , :image=>:update ,:method=>:post, :remote=> true 
    t.action :entities_contact_delete , :image=>:delete , :method=>:post, :remote=> true
  end
  
  def entities_display
    access :contacts
    @company = @current_company
    @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id) 
    session[:current_entity] = @entity.id
    contacts_list params
    @contact = Contact.new
  end
  
  def entities_contact_create
    
    if request.post?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.new(params[:contact])
      @contact.company_id = @current_company.id
      @contact.norm = @current_company.address_norms[0]
      @contact.entity_id = @entity.id
      if @contact
        if request.xhr?
          render :action => "entities_contact_create.rjs"
        else
          redirect_to :action=>:entities_display, :id=>@entity.id if @contact.save
        end
      else
        if request.xhr?
          redirect_to :action=>:entities_contact_create , :id=>@entity.id
        else
          redirect_to :action=>:entities_contact_create , :id=>@entity.id
        end
      end
    end
  end

  def entities_contact_update
    if request.post?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.find_by_id_and_entity_id(params[:id], session[:current_entity])
      if request.xhr?
        render :action => "entities_contact_update.rjs"
      else
        redirect_to :action =>:entities_display, :id=>@entity.id if @contact.update_attributes(params[:contact])
      end
    end
  end
  
  def entities_contact_delete
    if request.post? or request.delete?
      @entity = Entity.find(session[:current_entity])
      @contact = Contact.find_by_id_and_company_id(params[:id] , @current_company.id )
      if request.xhr?  
        render :action => "entities_contact_delete.rjs"
      else
        Contact.delete(params[:id]) if @contact
        redirect_to :action => :entities_display, :id=>@entity.id
      end
    end
  end
  
  def entities_search
   # @entity = Entity.find(session[:current_entity])
    if request.post?
      id = params[:formu][:numb].to_i
      @person = Entity.find_by_id(id)
      if @person
        redirect_to :action => :entities_display, :id=>@person.id
      else
        if params[:nament][:test] != ""
          attributes = [:name, :code]
          conditions = ["false"]
          key_words = params[:nament][:test].to_s.split(" ")
          for attribute in attributes
            for word in key_words
              conditions[0] += " OR "+attribute.to_s+" ILIKE '%'||?||'%'"
              conditions << word
            end
          end
          #raise Exception.new conditions.inspect
          @entities = Entity.find(:all, :conditions=>conditions)
          size = 0
          for x in  @entities
            size += 1
          end
          if size > 1 
            raise Exception.new 'ok'
          end
          #raise Exception.new size.to_i
          #raise Exception.new @entities.inspect
          render :action => 'entities_search'        
        else
          if params[:contact][:nam] != ""
            attributes = [:email, :fax, :mobile]
            conditions = ["false"]
            key_words = params[:contact][:nam]
            for attribute in attributes
              for word in key_words
                conditions[0] += " OR "+attribute.to_s+" ILIKE '%'||?||'%'"
                conditions << word
              end
            end
            @contacts = Contact.find(:all, :conditions=>conditions)
            #raise Exception.new @contacts.inspect
            render :action => 'entities_search'
          end
        end
      end
    end
  end
  
  def entities_create # pr langage_id prendre current_user.language_id ? puis sortir du _form
    access :entities                      #ou params[:user][:language_id]  // pareil pr nature_id
    if request.post?
      @entity = Entity.new(params[:entity])
      session[:current_entity] = @entity.id
      @entity.company_id = @current_company.id
      # @entity.language_id = @current_company.language.id
      redirect_to :action=>:entities if @entity.save
    else
      @entity = Entity.new
    end
    render_form
  end

 def entities_update
   access :entities
   @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
   if request.post? and @entity
     if @entity.update_attributes(params[:entity])
       redirect_to :action=>:entities
     end
   end
   render_form
 end

 def entities_delete
   access :entities
   if request.post? or request.delete?
     @entity = Entity.find_by_id_and_company_id(params[:id], @current_company.id)
     Entity.delete(params[:id]) if @entity
   end
   redirect_to :action=>:entities
 end

end
