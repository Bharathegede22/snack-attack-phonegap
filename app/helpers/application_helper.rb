module ApplicationHelper
	
	def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
  
	def render_flash
  	concat content_tag(:div, raw(flash[:notice]), :class => "alert alert-success") if flash[:notice] && !flash[:notice].empty?
  	concat content_tag(:div, raw(flash[:error]), :class => "alert alert-danger") if flash[:error] && !flash[:error].empty?
  	flash[:error] = flash[:notice] = nil
  end
  
	def resource_name
    :user
  end
 	
  def resource
    @resource ||= User.new
  end
 	
end
