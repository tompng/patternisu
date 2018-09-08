require 'sinatra/base'
Thread.new do
  p :before_fork
end.join

class WebApp < Sinatra::Base
  def initialize
    super
    p :initialized
    @aaa = rand
  end

  get '/' do
    "<b>#{__id__}</b><br>" + @aaa.to_s
  end

  def call(env) # avoid instance variable reset
    call! env
  end
end
