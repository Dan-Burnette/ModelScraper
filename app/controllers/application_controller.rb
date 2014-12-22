class ApplicationController < ActionController::Base
  require "net/http"
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  #Pass in a list of all URLs and it will find all the models and URLS
  #Used in scrapers_controller#show_model_graph  
  # def get_models_and_urls(url_array)
  #   url_array.each do |url|
  #     if (url.include?('.rb'))
  #       raw = Wombat.crawl do
  #         base_url url
  #         data({css: ".js-file-line"}, :list)
  #       end

  #       raw_data = raw["data"]
  #       raw_data.each do |item|
  #         if (item.include?('< ActiveRecord::Base'))
  #           model = item.split("<")[0].split()[-1].split(/(?=[A-Z])/).join("_").downcase
  #           @models.push(model)
  #           @model_urls.push(url)
  #           @models_that_extend_active_record_base.push(model)
  #         #Catch those models that inherit from a model which inherits from ActiveRecord::Base
  #         elsif (item.include?('<'))
  #           split_item = item.split(' ')
  #           extends_model = split_item[-1].tableize.singularize.downcase
  #           if (@models_that_extend_active_record_base.include?(extends_model))
  #             model = item.split("<")[0].split()[-1].split(/(?=[A-Z])/).join("_").downcase
  #             @models.push(model)
  #             @model_urls.push(url)
  #             @model_to_model_it_extends.store(model, extends_model)
  #           end
  #         end
  #       end
  #     end
  #   end
  # end

  # Pass in a list of all urls and it will find those that are rails controllers
  # used in scrapers_controller#show_repo_controllers
  def get_controller_urls(url_array)
    controller_urls = []
    url_array.each do |url| 
      if url.include?('controller.rb')
        controller_urls.push(url)
      end
    end
    controller_urls
  end

  def get_controller_actions(controller_url)
    controller_actions = []
    raw = Wombat.crawl do
      base_url controller_url
      data({css: ".js-file-line"}, :list)
    end

    raw_data = raw["data"]
    raw_data.each do |item|
      #Get non-commented lines with def in them
      if item.include?('def ') && !item.include?('#')
        action = item.split[1]
        controller_actions.push(action)
      end
    end
    controller_actions
  end

  #For checking if the schema can be found
  def url_exist?(url_string)
    url = URI.parse(url_string)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = (url.scheme == 'https')
    path = url.path if url.path.present?
    res = req.request_head(path || '/')
    res.code != "404" # false if returns 404 - not found
  rescue Exception => e
    false # false if can't find the server
  end


end
