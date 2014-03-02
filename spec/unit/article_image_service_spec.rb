require_relative "../../lib/persistence/database"
require_relative "../../lib/persistence/article_service"

describe Persistence::ArticleService do
  let(:storage) { Pharrell.instance_for(Fog::Storage::AWS::Directory) }
  let(:service) { Persistence::ArticleImageService.new(storage) }

  describe "#upload" do
    it "uploads the file" do
      file = { :filename => "test.png", :tempfile => Tempfile.new("test.png") }
      id = "1"

      service.upload(id, file)

      expect(storage.files.length).to eq(1)
      expect(storage.files.first.key).to eq("article1-test.png")
    end
  end
end