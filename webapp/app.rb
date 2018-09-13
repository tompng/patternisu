require 'sinatra/base'

Thread.new do
  # wait_for_db
  # wait_for_redis host: 'localhost'
  # wait_for_redis host: '12.34.56.67'
  # wait_for_redis host: '23.45.67.89'
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
