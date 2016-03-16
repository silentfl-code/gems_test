require 'open-uri'
require 'faraday'
require 'rest-client'
require 'benchmark'
require 'json'

URL = 'http://127.0.0.1:8080'.freeze
API_URI = '/api/v2/core/ping'.freeze
@n = 1000

def test_open_uri
  @n.times do
    r = open("#{URL}#{API_URI}").read
    raise Exception.new if JSON.parse(r)['status'] != 'happy'
  end
end

def test_faraday
  conn = Faraday.new(url: URL) do |f|
    #f.request  :url_encoded          # form-encode POST params
    #f.response :logger               # log requests to STDOUT
    f.adapter Faraday.default_adapter # make requests with Net::HTTP
  end
  @n.times do
    response = conn.get API_URI
    r = response.body
    raise Exception.new if JSON.parse(r)['status'] != 'happy'
  end
end

def test_faraday2
  @n.times do
    response = Faraday.get "#{URL}#{API_URI}"
    # r = Faraday.get "#{URL}#{API_URI}", page: 1, per_page: 100   # для передачи параметров
    # r = Faraday.post "#{URL}#{API_URI}", page: 1, per_page: 100   # post-запрос с параметрами
    r = response.body
    raise Exception.new if JSON.parse(r)['status'] != 'happy'
  end
end

def test_rest_client
  @n.times do
    r = RestClient.get "#{URL}#{API_URI}"
    raise Exception.new if JSON.parse(r)['status'] != 'happy'
  end
end

Benchmark.bm(14) do |b|
  b.report('open-uri:') { test_open_uri }
  b.report('faraday:') { test_faraday }
  b.report('faraday2:') { test_faraday2 }
  b.report('rest-client:') { test_rest_client }
end

# silent@ror ~/projects/faraday_test> ruby --version
# ruby 2.1.5p273 (2014-11-13 revision 48405) [x86_64-linux]
# silent@ror ~/projects/faraday_test> ruby faraday_example.rb
#               user     system      total        real
# open-uri:     0.370000   0.090000   0.460000 (  0.581338)
# faraday:      0.560000   0.060000   0.620000 (  0.743083)
# faraday2:     0.530000   0.070000   0.600000 (  0.673769)
# rest-client:  0.430000   0.080000   0.510000 (  0.574625)
# silent@ror ~/projects/faraday_test> rvm 2.2.3
# silent@ror ~/projects/faraday_test> ruby faraday_example.rb
#               user     system      total        real
# open-uri:     1.260000   0.110000   1.370000 (  1.514961)
# faraday:      0.490000   0.050000   0.540000 (  0.635360)
# faraday2:     0.450000   0.080000   0.530000 (  0.661501)
# rest-client:  0.490000   0.050000   0.540000 (  0.679300)
# silent@ror ~/projects/faraday_test> rvm jruby
# silent@ror ~/projects/faraday_test> ruby faraday_example.rb
#               user     system      total        real
# open-uri:     4.490000   0.150000   4.640000 (  3.476000)
# faraday:      3.830000   0.210000   4.040000 (  3.298000)
# faraday2:     3.000000   0.140000   3.140000 (  2.778000)
# rest-client:  9.020000   0.940000   9.960000 (  9.578000)
