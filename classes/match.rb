# frozen_string_literal: true

require 'mongo'
MONGO = Mongo::Client.new(['127.0.0.1:27017'], database: 'pubg')
COLLECTION = MONGO[:players]
class Match
  class << self
    def get(userid)
      m = COLLECTION.find({ userid: userid })
      if m.count.positive?
        m.first['matches']
      else
        {}
      end
    end

    def get_matches(userid)
      get(userid).map { |x| x['id'] }
    end

    def add(userid, match)
      q = if exist?(userid)
            COLLECTION.update_one({ "userid": userid }, { "$addToSet": { 'matches' => match } })
          else
            COLLECTION.insert_one({ "userid": userid, "matches": [match] })
          end
      if q.n.positive?
        true
      else
        false
      end
    end

    def exits_match?(userid, match)
      m = COLLECTION.find({ "$and": [{ "userid": userid }, { "matches": { "$elemMatch": { "id": match } } }] }).limit(1)
      if m.count.positive?
        true
      else
        false
      end
    end

    private

    def exist?(userid)
      m = COLLECTION.find({ userid: userid })
      if m.count.positive?
        true
      else
        false
      end
    end
  end
end
