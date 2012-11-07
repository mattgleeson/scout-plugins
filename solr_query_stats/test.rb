require File.expand_path('../../test_helper.rb', __FILE__)
require File.expand_path('../solr_query_stats.rb', __FILE__)

require 'open-uri'
class SolrQueryStatsTest < Test::Unit::TestCase

  def setup
    @stats_url = 'http://localhost:8983/solr/admin/stats.jsp'
    @now = Time.now
    @first = {
      :q_requests => 114397,
      :up_commits => 34121,
      :up_adds => 1411849,
    }
    @second = {
      :q_requests => 114612,
      :up_commits => 34164,
      :up_adds => 1411892,
    }
  end

  def teardown
    FakeWeb.clean_registry
  end

  def test_first_run
    FakeWeb.register_uri(:get, @stats_url, :body => File.read(File.dirname(__FILE__)+'/solr.xml.1'))
    @plugin = SolrQueryStats.new(@now, {}, {
                                   :stats_url => @stats_url
                                 })
    res = @plugin.run
    assert res[:errors].empty?
    out = res[:reports].first
    assert_equal 3055685, out[:numdocs]
    [:q_requests, :up_commits, :up_adds].each do |field|
      assert_equal @first[field], res[:memory]["_counter_#{field}"][:value]
    end
  end

  def test_second_run
    FakeWeb.register_uri(:get, @stats_url, :body => File.read(File.dirname(__FILE__)+'/solr.xml.2'))
    memory = {}
    @first.each_pair do |k,v|
      memory["_counter_#{k}"] = {:time=>@now-5*60, :value=>v}
    end
    @plugin = SolrQueryStats.new(@now-5*60, memory,
                                 {
                                   :stats_url => @stats_url
                                 })
    res = @plugin.run
    assert res[:errors].empty?
    assert_equal 3055706, res[:reports].map {|h| h[:numdocs] || 0 }.max()
    assert_in_delta (@second[:q_requests]-@first[:q_requests]).to_f/(5*60), res[:reports].map {|h| h[:q_requests] || 0 }.max(), 0.01
  end

end
