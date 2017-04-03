describe Matroid do

  describe 'Matroid#account_info' do
    # Keys generated specifically for the tests. Should be removed in the future
    let(:client_id) { 'c7RqWJs9MopTAN0Y' }
    let(:client_secret) { '55JxPSgh395wRW1IIX1PDLDBeVlUZytI' }

    before do
      VCR.use_cassette('authenticate:client') do
        Matroid.authenticate(client_id, client_secret)
      end
    end

    let(:account_info) do
      VCR.use_cassette('Matroid:account_info') do
        Matroid.account_info
      end
    end


    it 'should get correct account info' do
      credits = account_info['account']['credits']
      daily = credits['daily']
      monthly = credits['monthly']

      expect(credits['plan']).to                  eq('premium')
      expect(credits['concurrentTrainLimit']).to  eq(1)
    end
  end
end
