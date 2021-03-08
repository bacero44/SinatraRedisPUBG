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

  # attr_accessor :player
  # attr_accessor :body
  # attr_reader :date
  # attr_accessor :userid
  # def initialize(player = nil, body = {}, userid = nil)
  #   @player = player
  #   @body = body
  #   @userid = userid
  #   find unless player.nil?
  # end

  # def fund?
  #   if !player.nil? && !userid.nil? && !body.empty?
  #     true
  #   else
  #     false
  #   end
  # end

  # #   TODO:Validations to save and update
  # def create
  #   REDIS.json_set(player, Rejson::Path.root_path, body)
  #   REDIS.json_set(player, Rejson::Path.new('date'), Time.new)
  #   REDIS.json_set(player, Rejson::Path.new('userid'), userid)
  # end

  # def update
  #   REDIS.json_set(player, 'mastery', body[:mastery])
  #   REDIS.json_set(player, 'stats', body[:stats])
  #   REDIS.json_set(player, 'date', Time.new)
  # end

  # private

  # def find
  #   r = REDIS.json_get player, Rejson::Path.root_path
  #   unless r.nil?
  #     @date = DateTime.parse(r['date'])
  #     @userid = r['userid']
  #     @body = {
  #       'mastery' => r['mastery'],
  #       'stats' => r['stats']
  #     }

  #   end
  # end
end
