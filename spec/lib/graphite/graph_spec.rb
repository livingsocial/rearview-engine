require 'spec_helper'

describe Graphite::Graph do

  context '.with_url' do
    it 'should create a graph from the url' do
      url = '/render?width=600&from=-1days&until=now&height=400&target=alias(summarize(stats_counts.deals.payment.sale.sent%2C%221min%22)%2C%22Sent%22)&target=alias(summarize(stats_counts.deals.payment.sale.notification_received%2C%221min%22)%2C%22Received%22)&target=alias(diffSeries(summarize(stats_counts.deals.payment.sale.notification_received%2C%221min%22)%2Csummarize(stats_counts.deals.payment.sale.sent%2C%221min%22))%2C%22Difference%22)&title=Payment_Sale_Per_Minute&yMin=&yMax=&_uniq=0.8545389957472919'
      graph = Graphite::Graph.from_url(url)
      expect(graph.targets.size).to eq(3)
      expect(graph.from).to eq('-1days')
      expect(graph.until).to eq('now')
      expect(graph.title).to eq('Payment_Sale_Per_Minute')
    end
  end

end

