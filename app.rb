# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'yaml'
require_relative('helpers')
# 3600 === 1 hour
REFRESHMENT_TIME = 3600
Dir[settings.root + '/classes/*.rb'].sort.each { |file| require file }
before do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*'
end
get '/player/:nametag' do
  nametag = params[:nametag]
  redis = Redis.new(nametag)

  if redis.fund?

    if (Time.now - Time.parse(redis.date.to_s)) / REFRESHMENT_TIME > 2
      pubg = Pubg.new(nametag, redis.userid)
      pubg.get
      redis.body = { "mastery": pubg.mastery, "stats": pubg.stats }
      redis.update
    end
    json_response(redis.body, 200)

  else
    pubg = Pubg.new(nametag)
    pubg.get
    if pubg.fund?

      redis.body = { "mastery": pubg.mastery, "stats": pubg.stats }
      redis.userid = pubg.userid
      redis.create

      json_response(redis.body, 200)
    else
      json_response({
                      "message": " We can't fund the player",
                      "data": 'no data'
                    }, 404)

    end
  end
end

get '/weapons' do
  json_response(Pubg.class_variable_get(:@@weapons), 200)
end
