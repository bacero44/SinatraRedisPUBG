# frozen_string_literal: true

require 'rejson'
REDIS = Redis.new({ password: CONFIG['redis_pasword'] })
class Redis
  class << self
    def get_player(nametag)
      r = REDIS.json_get nametag, Rejson::Path.root_path
      if !r.nil?
        {
          'date' => DateTime.parse(r['date']),
          'userid' => r['userid'],
          'mastery' => r['mastery'],
          'stats' => r['stats']
        }
      else
        false
      end
    end

    def save_player(player)
      REDIS.json_set(player.nametag, Rejson::Path.root_path, {
                       'userid' => player.userid,
                       'stats' => player.stats,
                       'mastery' => player.mastery,
                       'date' => Time.new

                     })
    end

    def update_player(player)
      REDIS.json_set(player.nametag, 'stats', player.stats)
      REDIS.json_set(player.nametag, 'mastery', player.mastery)
      REDIS.json_set(player.nametag, 'date', Time.new)
    end
  end

end
