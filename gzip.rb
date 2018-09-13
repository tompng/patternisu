require 'sinatra'
require 'zlib'
require 'pry'
get '/' do
  last_modified = env['HTTP_IF_MODIFIED_SINCE']
  etag = env['HTTP_IF_NONE_MATCH']
  last_modified = Time.parse last_modified if last_modified
  return 304 if last_modified || etag
  tags = Array.new 1024 do
    tag = %w[div b span p h1 h2 h3 h4 h5 i].sample
    "<#{tag}>#{methods.sample}</#{tag}>"
  end
  html = tags.join "\n"
  return html unless env['HTTP_ACCEPT_ENCODING']&.include? 'gzip'
  headers['Content-Encoding'] = :gzip
  last_modified Time.at Time.now.to_i
  etag Time.now.to_i.to_s
  compressed = Zlib.gzip html
  puts "#{html.size}->#{compressed.size} #{compressed.size.fdiv html.size}"
  compressed # must cache it!
end
