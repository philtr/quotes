require 'sinatra'
require 'sequel'

configure { DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/quotes.db') } 

class Quote < Sequel::Model ; end
class OffensiveQuote < Sequel::Model(:quotes_o) ; end

before do
  request.path_info.gsub!(/\/o$/) { @o = true; "" }
  request.path_info = "/" if request.path_info.empty?
  QuoteType = @o ? OffensiveQuote : Quote
end

get '/' do
  @quotes = QuoteType.reverse_order(:id)
  erb :index
end

get '/id/:id/?' do
  @quotes = QuoteType.filter(:id => params[:id]).all
  erb :index
end

get '/channel/:irc_chan/?' do
  @quotes = QuoteType.filter(:irc_chan => params[:irc_chan]).all
  erb :index
end

get '/by/:attrib/?' do
  @quotes = QuoteType.filter(:attrib => params[:attrib]).all
  erb :index
end

get '/submit/?' do
  @action = 'submit'
  erb :submit
end

put '/create/?' do
  @quote = QuoteType.create({ 
    :quote => params[:quote], 
    :attrib => params[:attrib], 
    :context => params[:context],
    :irc => params[:irc].to_i,
    :irc_chan => params[:irc_chan],
    :date => Time.now.to_i
    })
  @quote.save
  redirect @o ? '/o' : '/'
end

helpers do
  def partial(name, options = {})
    item_name = name.to_sym
    counter_name = "#{name}_counter".to_sym
    if collection = options.delete(:collection)
      collection.enum_for(:each_with_index).collect do |item, index|
        partial(name, options.merge(:locals => { item_name => item, counter_name => index + 1 }))
      end.join
    elsif object = options.delete(:object)
      partial name, options.merge(:locals => {item_name => object, counter_name => nil})
    else
      erb "_#{name}".to_sym, options.merge(:layout => false)
    end
  end

  def nl2br(text)
    text.gsub(/[\r\n]+/, '<br />')
  end

  def html_escape(text)
    ERB::Util.html_escape(text)
  end
  
  def o_value ; @o ? "/o" : "/" ; end
end
  