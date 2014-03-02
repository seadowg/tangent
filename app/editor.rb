class Editor < Base
  helpers Sinatra::Nedry

  include Pharrell::Injectable
  injected :clock, System::Clock
  injected :storage, Fog::Storage::AWS::Directory

  before do
    if ENV["RACK_ENV"] == "production"
      # Redirect to heroku/https for editor
      if request.path.start_with?("/editor") && request.scheme == "http"
        redirect to("https://#{ENV["HOSTNAME"]}#{request.path}")

      # Redirect to domain/http for anything else
      elsif !request.path.start_with?("/editor") && request.scheme == "https"
        redirect to("http://#{ENV["DOMAIN"]}#{request.path}")
      end
    end
  end

  get '/editor/?' do
    protected! do
      erb :editor, :layout => :editor_layout
    end
  end

  get '/editor/articles/?' do
    protected! do
      articles = article_service.fetch_all
      erb :editor_articles, :locals => { :articles => articles }, :layout => :editor_layout
    end
  end

  get '/editor/articles/new/?' do
    protected! do
      erb :editor_articles_new, :locals => { :categories => Categories::ALL }, :layout => :editor_layout
    end
  end

  get '/editor/articles/:id/?' do
    protected! do
      article = article_service.fetch(params[:id])
      widget = Widget::Article.new(article)

      erb :editor_articles_show, :locals => { :article => widget }, :layout => :editor_layout
    end
  end

  get '/editor/articles/:id/edit/?' do
    protected! do
      article = article_service.fetch(params[:id])
      erb :editor_articles_edit, :locals => { :article => article, :categories => Categories::ALL }, :layout => :editor_layout
    end
  end

  post "/editor/articles/?" do
    protected! do
      article_params = params[:article]

      image_url = if article_params[:image]
        upload_image(
          article_params[:image][:filename],
          article_params[:image][:tempfile]
        )
      else
        nil
      end

      article_service.create(
        article_params[:author],
        article_params[:title],
        article_params[:category],
        article_params[:content],
        image_url
      )

      redirect to("/editor/articles")
    end
  end

  put "/editor/articles/:id/?" do
    protected! do
      article_params = params[:article]

      image_url = if article_params[:image]
        upload_image(
          article_params[:image][:filename],
          article_params[:image][:tempfile]
        )
      else
        nil
      end

      article_service.update(params[:id],
        article_params[:author],
        article_params[:title],
        article_params[:category],
        article_params[:content],
        image_url
      )

      redirect to("/editor/articles/#{params[:id]}")
    end
  end

  delete "/editor/articles/:id/?" do
    protected! do
      article_service.delete(params[:id])
      redirect to("/editor/articles")
    end
  end

  post "/editor/articles/:id/publishing/?" do
    protected! do
      publisher = Domain::ArticlePublisher.new(params[:id], article_service)
      article = publisher.publish(clock.now)

      if article.error
        erb :editor_articles_edit, :locals => { :article => article, :categories => Categories::ALL }, :layout => :editor_layout
      else
        redirect to("/editor/articles/#{params[:id]}")
      end
    end
  end

  delete "/editor/articles/:id/publishing/?" do
    protected! do
      article_service.unpublish(params[:id])
      redirect to("/editor/articles/#{params[:id]}")
    end
  end

  get "/editor/categories/?" do
    protected! do
      erb :editor_categories, :locals => { :categories => Categories::ALL }, :layout => :editor_layout
    end
  end

  get "/editor/categories/:id/?" do
    protected! do
      category = Categories.fetch(params[:id])
      articles = article_service.fetch_all_from_category(category.id)
      erb :editor_categories_show, :locals => { :category => category, :articles => articles }, :layout => :editor_layout
    end
  end

  private

  def upload_image(file_name, file)
    file = storage.files.create(
      :key => file_name,
      :body => file,
      :public => true
    )

    file.public_url
  end
end
