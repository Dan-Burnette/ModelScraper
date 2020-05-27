require_relative "models/github_repository"
require_relative "models/association"
require_relative "services/parse_class_name"
require_relative "services/parse_associations"
require_relative "services/parse_schema_tables"
require_relative "services/create_graph"

get '/' do
  erb :index
end

get '/visualize_repo' do
  begin
    repo = GithubRepository.new(repo_url)
    @table_names_to_column_lines = ParseSchemaTables.call(repo.schema_file_content)
    CreateGraph.call(repo_name, models_to_associations(repo))
    erb :visualize
  rescue Octokit::NotFound, Octokit::InvalidRepository => error
    @error_message = "Couldn't find that repository. Is it entered correctly?"
    @attempted_url = repo_url
    erb :index
  rescue GithubRepository::NoSchemaFound => error
    @error_message = "Couldn't find the database schema for that repository! Looking for db/schema.rb."
    @attempted_url = repo_url
    erb :index
  rescue StandardError => error
    production? ? Rollbar.error(error, url: repo_url) : raise(error)
    @error_message = "Something went wrong visualizing that repository. I'll look into a fix."
    @attempted_url = repo_url
    erb :index
  end
end

def repo_url
  params[:repo_root_url]
end

def repo_name
  repo_url.split('/')[-1]
end

def models_to_associations(repo)
  model_file_contents = repo.model_file_contents
  model_classes = model_file_contents.map { |contents| ParseClassName.call(contents) }

  result = {}
  model_file_contents.each_with_index do |file_content, i|
    class_name = model_classes[i]
    associations = ParseAssociations.call(model_classes, class_name, file_content)
    result[class_name] = associations
  end
  result
end

def production?
  ENV.fetch("APP_ENV") == "production"
end

def inline_svg(file_name)
  file_path = "public/images/#{file_name}"
  File.read(file_path) 
end
