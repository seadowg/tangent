class Base < Sinatra::Base
  enable :method_override, :logging
  set :public_folder, 'public'
  
  include Pharrell::Injectable
  injected :article_service, Persistence::ArticleService
  injected :category_service, Persistence::CategoryService
end