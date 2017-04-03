describe Matroid::Detector do
  # Keys generated specifically for the tests. Should be removed in the future
  let(:client_id) { 'c7RqWJs9MopTAN0Y' }
  let(:client_secret) { '55JxPSgh395wRW1IIX1PDLDBeVlUZytI' }

  before do
    VCR.use_cassette('authenticate:client') do
      Matroid.authenticate(client_id, client_secret)
    end
  end

  describe 'Detector::find receiving id as a string' do

    before(:each) do
      # Get Arctic Monkeys's "Do I Wanna Know?" detector as a testing sample
    end

    it 'should find detector with correct attributes' do
      detector = VCR.use_cassette('detector:find:587ed72bb9b549417eefba41') do
        Matroid::Detector.find('587ed72bb9b549417eefba41')
      end
      expect(detector.id)                       .to eq '587ed72bb9b549417eefba41'
      expect(detector.name)                     .to eq 'cat-64'
      expect(detector.labels)                   .to include 'cat'
      expect(detector.permission)               .to eq 'open'
      expect(detector.is_owner)                 .to eq true
    end
  end

  describe 'Detector::find receiving array of ids' do
    it 'should find the right tracks' do
      ids = ['58795ad046f692f904881de6']
      detector = VCR.use_cassette('detector:find:58795ad046f692f904881de6') do
        Matroid::Detector.find(ids)
      end
      expect(tracks)            .to be_an Array
      expect(tracks.size)       .to eq 1
      expect(tracks.first.name) .to eq 'rya-60'

      ids << '58a7878ec4efabc153626132'
      tracks = VCR.use_cassette('detector:find:58a7878ec4efabc153626132') do
        Matroid::Detector.find(ids)
      end
      expect(tracks)            .to be_an Array
      expect(tracks.size)       .to eq 2
      expect(tracks.first.name) .to eq 'rya-60'
      expect(tracks.last.name)  .to eq 'rya-92'
    end
  end

  describe 'Detector::search' do
    it 'should search for the right tracks' do
      tracks = VCR.use_cassette('detector:search:Wanna Know') do
        Matroid::Detector.search('Wanna Know')
      end
      expect(tracks)             .to be_an Array
      expect(tracks.size)        .to eq 20
      expect(tracks.total)       .to eq 3647
      expect(tracks.first)       .to be_an Matroid::Detector
      expect(tracks.map(&:name)) .to include('Do I Wanna Know?', 'I Wanna Know', 'Never Wanna Know')
    end

    it 'should accept additional options' do
      tracks = VCR.use_cassette('detector:search:Wanna Know:limit:10') do
        Matroid::Detector.search('Wanna Know', limit: 10)
      end
      expect(tracks.size)        .to eq 10
      expect(tracks.map(&:name)) .to include('Do I Wanna Know?', 'I Wanna Know')

      tracks = VCR.use_cassette('detector:search:Wanna Know:offset:10') do
        Matroid::Detector.search('Wanna Know', offset: 10)
      end
      expect(tracks.size)        .to eq 20
      expect(tracks.map(&:name)) .to include('They Wanna Know', 'You Wanna Know')

      tracks = VCR.use_cassette('detector:search:Wanna Know:limit:10:offset:10') do
        Matroid::Detector.search('Wanna Know', limit: 10, offset: 10)
      end
      expect(tracks.size)        .to eq 10
      expect(tracks.map(&:name)) .to include('You Wanna Know')

      tracks = VCR.use_cassette('detector:search:Wanna Know:market:ES') do
        Matroid::Detector.search('Wanna Know', market: 'ES')
      end
      ES_tracks = tracks.select { |t| t.available_markets.include?('ES') }
      expect(ES_tracks.length).to eq(tracks.length)
    end
  end

  describe 'Detector#audio_features' do
    let(:client_id) { '5ac1cda2ad354aeaa1ad2693d33bb98c' }
    let(:client_secret) { '155fc038a85840679b55a1822ef36b9b' }

    before do
      VCR.use_cassette('authenticate:client') do
        Matroid.authenticate(client_id, client_secret)
      end
    end

    let(:detector) do
      VCR.use_cassette('detector:find:3jfr0TF6DQcOLat8gGn7E2') do
        Matroid::Detector.find('3jfr0TF6DQcOLat8gGn7E2')
      end
    end

    it 'retrieves the audio features for the detector' do
      audio_features = VCR.use_cassette('detector:audio_features:3jfr0TF6DQcOLat8gGn7E2') do
        detector.audio_features
      end

      expect(audio_features.acousticness).to     eq 0.186
      expect(audio_features.analysis_url).to     eq 'http://echonest-analysis.s3.amazonaws.com/TR/TR-mGwgsahAQuIJvg1GFm9sHdVOQa1Tq677JbupMzwMyyKB_i5PBIKWWtTxnarW-qvlA9zRYF6OIY6cnU=/3/full.json?AWSAccessKeyId=AKIAJRDFEY23UEVW42BQ&Expires=1460833574&Signature=5binEjpotRQp8%2BE3LdYipDL%2BE8E%3D'
      expect(audio_features.danceability).to     eq 0.548
      expect(audio_features.duration_ms).to      eq 272394
      expect(audio_features.energy).to           eq 0.532
      expect(audio_features.instrumentalness).to eq 0.000263
      expect(audio_features.key).to              eq 5
      expect(audio_features.liveness).to         eq 0.217
      expect(audio_features.loudness).to         eq -7.596
      expect(audio_features.mode).to             eq 1
      expect(audio_features.speechiness).to      eq 0.0323
      expect(audio_features.tempo).to            eq 85.030
      expect(audio_features.time_signature).to   eq 4
      expect(audio_features.track_href).to       eq 'https://api.spotify.com/v1/tracks/3jfr0TF6DQcOLat8gGn7E2'
      expect(audio_features.valence).to          eq 0.428
    end
  end
end
