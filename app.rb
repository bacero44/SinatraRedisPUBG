# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'yaml'
require_relative('helpers')

Dir[settings.root + '/classes/*.rb'].sort.each { |file| require file }

also_reload settings.root + '/classes/player.rb'
also_reload settings.root + '/classes/match.rb'
also_reload settings.root + '/classes/pubg.rb'



before do
  content_type :json
  headers 'Access-Control-Allow-Origin' => '*'
  # sleep(2)
end
get '/player/:nametag' do
  player = Player.new(params[:nametag])
  if player.fund?
    json_response({ stats: player.stats, mastery: player.mastery }, 200)
  else
    json_response({ "message": " We can't fund the player", "data": 'no data' }, 404)
  end
end
get '/player/:nametag/matches' do
  player = Player.new(params[:nametag])
  if player.fund?
    json_response({ matches: player.matches }, 200)
  else
    json_response({ "message": " We can't fund the player", "data": 'no data' }, 404)
  end
end
get '/weapons' do
  json_response(Pubg.class_variable_get(:@@weapons), 200)
end
