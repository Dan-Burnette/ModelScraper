class ScrapersController < ApplicationController
  require 'graphviz'
 # GENERATE A DIAGRAM OF A RAILS APP'S MODEL RELATIONSHIPS!

  def index

  end

  def show
    start_url = params[:start_url]

    #Scrape for the models
    @raw = Wombat.crawl do
      base_url start_url
      data({css: ".css-truncate"}, :list)
    end

    @models = []
    @model_urls = []
    @raw_data = @raw["data"]

    #Process raw data into models and URLS to their pages
    @raw_data.each do |item|
      model_and_extension = item.split('.')
      if (model_and_extension.include?('rb'))
        model = model_and_extension[0]
        @models.push(model)
        model_url = start_url + '/' + model_and_extension.join('.')
        @model_urls.push(model_url)
      end
    end

    @all_lines = []
    @all_relationships = []
    
    #Scrape each model page for their activeRecord assocations
    @model_urls.each do |url|

      lines = Wombat.crawl do 
        base_url url
        data({css: ".js-file-line"}, :list)
      end

      lines = lines["data"]
      @all_lines.push(lines)

      relationships = []
      lines.each do |line|
        if (line.include?("belongs_to") || line.include?("has_one") ||
            line.include?("has_many") || line.include?("belongs_to"))
            relationships.push(line)
        end 
      end

      @all_relationships.push(relationships)

    end

    #Graphing logic
    g = GraphViz.new(:G, :type => :digraph )
    #Create a node for each model
    nodes = []
    @models.each do |m|
      nodes.push(g.add_nodes(m))
    end

    puts "ALL RELATIONSHIPS ======="
      puts @all_relationships.inspect
      #Generating appropriate edges
      nodes.each_with_index do |node, i|
        relationships = @all_relationships[i]
        puts relationships.inspect
        relationships.each do |r|
          relationship_parts = r.split(':', 2)
          relationship = relationship_parts[0]
          nodeToConnect = relationship_parts[1].delete(':')
         
          puts "RELATIONSHIP PARTS: RELATIONSHIP THEN NODETOCONNECT"
          puts relationship
          puts nodeToConnect
          edge = g.add_edges(node, nodeToConnect)
          edge[:label => relationship]
        
        end

      end

      g.output(:png => "app/assets/images/test.png")

  end
  
end
