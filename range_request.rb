require 'sinatra'
# curl http://localhost:4567/data -r 32-48

get '/file' do
  send_file __FILE__ # range request ok
end

get '/data' do
  $data ||= File.binread(__FILE__)
  ranges = Rack::Utils.get_byte_ranges(request.get_header('HTTP_RANGE'), $data.size)
  if ranges&.size == 1
    range = ranges.first
    status 206
    headers['Content-Range'] = "bytes #{range.begin}-#{range.end}/#{$data.size}"
    return '' if request.head?
    $data[range]
  else
    $data
  end
end
