require 'benchmark'
require 'faraday'
require 'json'
require 'parallel'
require 'typhoeus'
require 'agent'

URL = 'http://127.0.0.1:8080'.freeze
API_URI = '/api/v2/core/users'.freeze
@n = 1000

def test_sequential
  @n.times do
    r = Faraday.get "#{URL}#{API_URI}", page: 1, per_page: 100
    raise Exception.new if JSON.parse(r.body)[0]['name'] != 'user1'
  end
end

def test_parallel_processes
  Parallel.map((0..@n), in_process: 8) do
    r = Faraday.get "#{URL}#{API_URI}", page: 1, per_page: 100
    raise Exception.new if JSON.parse(r.body)[0]['name'] != 'user1'
  end
end

def test_parallel_threads
  Parallel.map((0..@n), in_threads: 8) do
    r = Faraday.get "#{URL}#{API_URI}", page: 1, per_page: 100
    raise Exception.new if JSON.parse(r.body)[0]['name'] != 'user1'
  end
end

def test_typhoeus
  hydra = Typhoeus::Hydra.new(max_concurrency: 20)
  @n.times do
    request = Typhoeus::Request.new("#{URL}#{API_URI}")
    request.on_complete do |response|
      raise Exception.new if JSON.parse(response.body)[0]['name'] != 'user1'
    end
    hydra.queue(request)
  end
  hydra.run
end

def test_agent
  ch = channel!(Boolean, 10)
  @n.times do
    go! do
      r = Faraday.get "#{URL}#{API_URI}", page: 1, per_page: 100
      ch << true
      raise Exception.new if JSON.parse(r.body)[0]['name'] != 'user1'
    end
  end
  @n.times { tmp << ch }
end

Benchmark.bm(30) do |b|
  b.report('sequential: ') { test_sequential }

  b.report('parallel (processes):') { test_parallel_processes }
  b.report('parallel (threads):') { test_parallel_threads }

  b.report('typhoeus: ') { test_typhoeus }

  b.report('agent: ') { test_typhoeus }
end

# silent@ror ~/projects/faraday_test> rvm 2.1
# silent@ror ~/projects/faraday_test> ruby faraday_parallel.rb                                                                                                                                                                         master!
#                                      user     system      total        real
# sequential:                      0.650000   0.090000   0.740000 (  0.881919)
# parallel (processes):            0.030000   0.010000   0.850000 (  0.602617)
# parallel (threads):              0.720000   0.160000   0.880000 (  0.967304)
# typhoeus:                        0.250000   0.020000   0.270000 (  0.277061)
# agent:                           0.260000   0.010000   0.270000 (  0.280704)
#
# silent@ror ~/projects/faraday_test> rvm 2.2.3                                                                                                                                                                                        master!
# silent@ror ~/projects/faraday_test> ruby faraday_parallel.rb                                                                                                                                                                         master!
#                                      user     system      total        real
# sequential:                      0.600000   0.080000   0.680000 (  0.795192)
# parallel (processes):            0.030000   0.010000   0.700000 (  0.520697)
# parallel (threads):              0.670000   0.090000   0.760000 (  0.853930)
# typhoeus:                        0.290000   0.020000   0.310000 (  0.304606)
# agent:                           0.270000   0.000000   0.270000 (  0.284758)
#
# silent@ror ~/projects/faraday_test> rvm jruby 
# silent@ror ~/projects/faraday_test> ruby faraday_parallel.rb                                                                                                                                                                         master!
#                                      user     system      total        real
# sequential:                      9.020000   0.240000   9.260000 (  6.073000)
# parallel (processes):            3.120000   0.190000   3.310000 (  2.418000)
# parallel (threads):              2.420000   0.140000   2.560000 (  2.639000)
# typhoeus:                        2.480000   0.010000   2.490000 (  2.358000)
# agent:                           1.390000   0.060000   1.450000 (  1.926000)
