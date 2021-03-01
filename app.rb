# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'yaml'
# 3600 === 1 hour
REFRESHMENT_TIME = 3600
Dir[settings.root + '/classes/*.rb'].sort.each { |file| require file }
get '/player/:nametag' do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*'
  nametag = params[:nametag]
  redis = Redis.new(nametag)

  if redis.fund?

    if (Time.now - Time.parse(redis.date.to_s)) / REFRESHMENT_TIME > 2
      pubg = Pubg.new(nametag, redis.userid)
      pubg.get
      redis.body = { "mastery": pubg.mastery, "stats": pubg.stats }
      redis.update
    end
    status 200
    return redis.body.to_json

  else
    pubg = Pubg.new(nametag)
    pubg.get
    if pubg.fund?

      redis.body = { "mastery": pubg.mastery, "stats": pubg.stats }
      redis.userid = pubg.userid
      redis.create

      status 200
      return redis.body.to_json
    else
      status 404
      {
        "message": " We can't fund the player",
        "data": 'no data'
      }.to_json
    end
  end
end
