require 'elasticsearch/model'
class Article < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  paginates_per 10

  def self.search(query)
    __elasticsearch__.search(
      {
        query: {
          multi_match: {
            query: query,
            fields: ['title^10', 'description']
          }
        },
        highlight: {
          pre_tags: ['<mark>'],
          post_tags: ['</mark>'],
          fields: {
            title: {},
            description: {}
          }
        }
      }
    )
  end

  settings index: { number_of_shards: 1 } do
    mappings dynamic: 'false' do
      indexes :title, analyzer: 'english', type: 'string'
      indexes :description, analyzer: 'english', type: 'string'
    end
  end

  def self.manual_search(query)
    where("title like ? OR description like ?", "%#{query}", "%#{query}%").uniq
  end

  def self.compare(text)
    Benchmark.ips do |x|
      x.report("elastic: ")   { Article.search(text) }
      x.report("manual: ")    { Article.manual_search(text) }

      x.compare!
    end
  end

  def self.bs_compare(text)
    puts "===== Elastic ===== "
    puts Benchmark.measure { Article.search(text)  }
    puts "===== Manual ===== "
    puts Benchmark.measure { Article.manual_search(text)  }
  end
end
# Article.__elasticsearch__.client.indices.delete index: Article.index_name rescue nil

# Article.__elasticsearch__.client.indices.create \
#   index: Article.index_name,
#   body: { settings: Article.settings.to_hash, mappings: Article.mappings.to_hash }

# Article.import