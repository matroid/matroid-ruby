describe Matroid::Detector do
  describe '.find_by_id' do

    it 'should find the right detector with correct attributes' do
      detector = VCR.use_cassette('detector:find_by_id:587ed72bb9b549417eefba41') do
        Matroid::Detector.find_by_id('587ed72bb9b549417eefba41')
      end
      expect(detector.id)                       .to eq '587ed72bb9b549417eefba41'
      expect(detector.name)                     .to eq 'cat-64'
      expect(detector.labels)                   .to include 'cat'
      expect(detector.permission_level)         .to eq 'private'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end
  end

  describe '.find_one' do

    it 'should find the right detector with correct attributes searching for id' do
      detector = VCR.use_cassette('detector:find_one:id:587ed72bb9b549417eefba41') do
        Matroid::Detector.find_one(id: '587ed72bb9b549417eefba41')
      end

      expect(detector.id)                       .to eq '587ed72bb9b549417eefba41'
      expect(detector.name)                     .to eq 'cat-64'
      expect(detector.labels)                   .to include 'cat'
      expect(detector.permission_level)         .to eq 'private'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end

    it 'should find the right detector with correct attributes searching for state' do
      detector = VCR.use_cassette('detector:find_one:state:trained') do
        Matroid::Detector.find_one(state: 'trained')
      end
      expect(detector.id)                       .to eq '583416bc01f5b1394b3875c5'
      expect(detector.name)                     .to eq 'kitties-n-puppies'
      expect(detector.labels)                   .to include 'kitty'
      expect(detector.permission_level)         .to eq 'open'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end

    it 'should find the right detector with correct attributes searching for labels' do
      detector = VCR.use_cassette('detector:find_one:labels:kitty') do
        Matroid::Detector.find_one(label: 'kitty')
      end
      expect(detector.id)                       .to eq '583416bc01f5b1394b3875c5'
      expect(detector.name)                     .to eq 'kitties-n-puppies'
      expect(detector.labels)                   .to include 'kitty'
      expect(detector.permission_level)         .to eq 'open'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end

    it 'should find the right detector with correct attributes searching for type' do
      detector = VCR.use_cassette('detector:find_one:type:object') do
        Matroid::Detector.find_one(type: 'object')
      end
      expect(detector.id)                       .to eq '583416bc01f5b1394b3875c5'
      expect(detector.name)                     .to eq 'kitties-n-puppies'
      expect(detector.labels)                   .to include 'kitty'
      expect(detector.permission_level)         .to eq 'open'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end

    it 'should find the right detector with correct attributes searching for permission_level' do
      detector = VCR.use_cassette('detector:find_one:permission_level:open') do
        Matroid::Detector.find_one(permission_level: 'open')
      end
      expect(detector.id)                       .to eq '583416bc01f5b1394b3875c5'
      expect(detector.name)                     .to eq 'kitties-n-puppies'
      expect(detector.labels)                   .to include 'kitty'
      expect(detector.permission_level)         .to eq 'open'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end

    it 'should find the right detector with correct attributes searching for published' do
      detector = VCR.use_cassette('detector:find_one:published:true') do
        Matroid::Detector.find_one(published: true)
      end
      expect(detector.id)                       .to eq '583416bc01f5b1394b3875c5'
      expect(detector.name)                     .to eq 'kitties-n-puppies'
      expect(detector.labels)                   .to include 'kitty'
      expect(detector.permission_level)         .to eq 'open'
      expect(detector.owner)                    .to eq true
      expect(detector.state)                    .to eq 'trained'
      expect(detector.type)                     .to eq 'object'
    end
  end

  describe '#classify_image_url' do
    let(:detector) do
      VCR.use_cassette('Matroid:Detector:kitties') do
        Matroid::Detector.find_by_id('58548cbc012b4b7016368453')
      end
    end

    it 'should classify image url' do
      p detector
      classification = VCR.use_cassette('detector:classify_image_url') do
        detector.classify_image_url('https://www.allaboutbirds.org/guide/PHOTO/LARGE/common_tern_donnalynn.jpg')
      end
      p classification
      expect(classification) .to eq true
    end
  end
end
