class SolrQueryStats < Scout::Plugin
  needs 'nokogiri', 'open-uri'

  OPTIONS = <<END_OPTIONS
stats_url:
  name: Stats URL
  notes: URL to the Solr stats.jsp page
  default: http://localhost:8983/solr/admin/stats.jsp
END_OPTIONS

  def build_report
    stats_xml = Nokogiri::XML(open(option(:stats_url)))
    solr_info = stats_xml.xpath('/solr/solr-info').first
    counter(:q_requests, solr_info.xpath("QUERYHANDLER/entry/name[contains(text(),'search')]/../stats/stat[@name='requests']").first.content.to_i, :per=>:second)
    counter(:up_commits, solr_info.xpath("UPDATEHANDLER/entry/name[contains(text(),'updateHandler')]/../stats/stat[@name='commits']").first.content.to_i, :per=>:second)
    counter(:up_adds, solr_info.xpath("UPDATEHANDLER/entry/name[contains(text(),'updateHandler')]/../stats/stat[@name='cumulative_adds']").first.content.to_i, :per=>:second)
    report({
             :numdocs => solr_info.xpath("CORE/entry/name[contains(text(),'searcher')]/../stats/stat[@name='numDocs']").first.content.to_i,
           })
  end
end
