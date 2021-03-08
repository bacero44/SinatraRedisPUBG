# frozen_string_literal: true

# 3600 === 1 hour
REFRESHMENT_TIME = 3600
class Player
  attr_reader :nametag
  attr_reader :userid
  attr_reader :mastery
  attr_reader :stats
  attr_reader :date

  def initialize(nametag)
    @nametag = nametag
    @userid = nil
    @mastery = nil
    @stats = nil
    @date = nil

    find_user
  end

  def fund?
    if !@userid.nil? || @userid
      true
    else
      false
    end
  end

  private

  def find_user
    redis = Redis.get_player(@nametag)
    if redis
      @userid = redis['userid']
      @mastery = redis['mastery']
      @stats = redis['stats']
      @date = redis['date']
      if (Time.now - Time.parse(@date.to_s)) / REFRESHMENT_TIME > 2
        Redis.update_player(self) if current_data_pubg
      end
    else
      pubg = Pubg.get_player(@nametag)
      if pubg
        @userid = pubg
        Redis.save_player(self) if current_data_pubg
      end
    end
  end

  def current_data_pubg
    @stats = Pubg.get_stats(@userid)
    @mastery = Pubg.get_mastery(@userid)
    if @stats && @mastery
      true
    else
      false
    end
  end
end
