# frozen_string_literal: true

require 'rejson'
REDIS = Redis.new({ password: CONFIG['redis_pasword'] })
class Redis
  attr_accessor :player
  attr_accessor :body
  attr_reader :date
  attr_accessor :userid
  def initialize(player = nil, body = {}, userid = nil)
    @player = player
    @body = body
    @userid = userid
    find unless player.nil?
  end

  def fund?
    if !player.nil? && !userid.nil? && !body.empty?
      true
    else
      false
    end
  end

  #   TODO:Validations to save and update
  def create
    REDIS.json_set(player, Rejson::Path.root_path, body)
    REDIS.json_set(player, Rejson::Path.new('date'), Time.new)
    REDIS.json_set(player, Rejson::Path.new('userid'), userid)
  end

  def update
    REDIS.json_set(player, 'mastery', body[:mastery])
    REDIS.json_set(player, 'stats', body[:stats])
    REDIS.json_set(player, 'date', Time.new)
  end

  private

  def find
    r = REDIS.json_get player, Rejson::Path.root_path
    unless r.nil?
      @date = DateTime.parse(r['date'])
      @userid = r['userid']
      @body = {
        'mastery' => r['mastery'],
        'stats' => r['stats']
      }

    end
  end
end
