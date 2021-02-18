# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
get '/:player' do
  "Hi fink #{params[:player]}"
end
