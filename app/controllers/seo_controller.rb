class SeoController < ApplicationController
	
	def explore
		@meta_title = @city.meta_title('inside')
		@meta_description = @city.meta_description('inside')
		@meta_keywords = @city.meta_keywords('inside')
		@canonical = @city.link('inside')
	end
	
	def index
		render_404 and return if !params[:id].include?('_')
		str,id = CommonHelper.decode(params[:id].split('_').last.strip)
		@object = case str
		when 'attraction' then Attraction.find(id)
		when 'cargroup' then Cargroup.find(id)
		when 'location' then Location.find(id)
		when 'page' then Page.find(id)
		else nil
		end
		render_404 and return if @object.nil?
		if str == 'page'
			link = @object.link
      head :moved_permanently, :location => link and return if request.url.split('?').first != link
			render text: @object.content.html_safe, layout: false and return
		else
			@meta_title = @object.meta_title(@city)
			@meta_description = @object.meta_description(@city)
			@meta_keywords = @object.meta_keywords(@city)
			@canonical = @object.link(@city)
			render "/seo/" + str
		end
	end
	
	def nearby
		@meta_title = @city.meta_title('outside')
		@meta_description = @city.meta_description('outside')
		@meta_keywords = @city.meta_keywords('outside')
		@canonical = @city.link('outside')
	end
	
end
