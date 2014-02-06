class ArticleService
  def initialize(db)
    @db = db
  end
  
  def fetch_all
    @db[:articles].all
  end
  
  def create(author, title, content)
    @db[:articles].insert(
      :author => author,
      :title => title,
      :content => content
    )
  end
end