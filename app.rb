require 'sinatra'
require 'slim'
require 'sassc'
require 'httparty'
require_relative './services/xml_convert_service'
require_relative './services/json_convert_service'

get '/' do
  slim :index
end

get '/json' do
  response = HTTParty.get(moex_url('xml'))

  content_type :json
  XmlConvertService.call(response.body)
end

get '/xml' do
  response = HTTParty.get(moex_url('json'))

  content_type :xml
  JsonConvertService.call(response.body)
end

get '/style.css' do
  scss :'../assets/stylesheets/style', style: :compressed
end

private

def moex_url(type)
  "https://iss.moex.com/iss/securities/#{ticker}.#{type}"
end

def ticker
  params[:ticker].to_s.strip.empty? ? 'RU000A10B4K3' : params[:ticker]
end
