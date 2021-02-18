# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
Dir[settings.root + '/classes/*.rb'].sort.each { |file| require file }

get '/:player' do
  @player = params[:player]
  pubg = Pubg.new(@player)
  pubg.get
  puts pubg.stats.inspect
  content_type :json
  return { "mastery": pubg.mastery, "stats": pubg.stats }.to_json
end
