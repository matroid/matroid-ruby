# size limit constants
IMAGE_FILE_SIZE_LIMIT = 50 * 1024 * 1024
VIDEO_FILE_SIZE_LIMIT = 300 * 1024 * 1024
BATCH_FILE_SIZE_LIMIT = 50 * 1024 * 1024
ZIP_FILE_SIZE_LIMIT   = 300 * 1024 * 1024
SEARCH_PARAMETERS     = %w(name label permission_level owner training type state)
module Matroid


  # Represents a Matroid detector
  # @attr [String]          id                Detector id
  # @attr [String]          name              Detector name
  # @attr [Array<Hash><String>]   labels
  # @attr [String]          permission_level  'private', 'readonly', 'open', 'stock'
  # @attr [Bool]            owner             is the current authicated user the owner
  class Detector
    # HASH { <id> => Detector }
    @@instances = {}
    @@ids = []

    attr_reader :id, :name, :labels, :label_ids, :permission_level, :owner, :training,
                :type, :state

    # Looks up the detector by matching fields.
    # :label and :name get matched according the the regular expression /\b(<word>)/i
    # @example
    #   Matroid::Detector.find(label: 'cat', state: 'trained')
    # @example
    #   Matroid::Detector.find(name: 'cat')
    # @example
    #   Matroid::Detector.find(name: 'cat', published: true)
    # @example
    #   Matroid::Detector.find(label: 'puppy').first.id
    # @note The detector must either be created by the current authenticated user or published for general use.
    # @return [Array<Hash><Detector>] Returns the detector instances that match the query.
    def self.find(args)
      raise Error::InvalidQueryError.new('Argument must be a hash.') unless args.class == Hash
      query = args.keys.map{|key| key.to_s + '=' + args[key].to_s }.join('&')
      detectors = Matroid.get('detectors/search?' + query)
      detectors.map{|params| register(params) }
    end

    # Chooses first occurence of the results from {#find}
    def self.find_one(args)
      args['limit'] = 1
      find(args).first
    end

    # Finds a single document based on the id
    def self.find_by_id(id, args = {})
      detector = @@instances[id]
      is_trained =  detector.class == Detector && detector.is_trained?
      return detector if is_trained

      args[:id] = id
      find_one(args)
    end

    SEARCH_PARAMETERS.each do |param|
      # Search for detectors using the "find_one_by_" method prefix
      define_singleton_method "find_one_by_#{param}" do |arg, opts = {}|
        opts[param.to_sym] = arg
        find_one(opts)
      end

      # Search for detectors using the "find_by_" method prefix
      define_singleton_method "find_by_#{param}" do |arg, opts = {}|
        opts[param.to_sym] = arg
        find(opts)
      end
    end

    #  List of cached detectors that have been returned by search requests as hashes or Detector instances.
    # @param type [String] Indicate how you want the response
    # @return [Array<Hash, Detector>]
    def self.cached(type = 'instance')
      case type
      when 'hash'
        @@ids.map{|id| find_by_id(id).to_hash }
      when 'instance'
        @@ids.map{|id| find_by_id(id) }
      end
    end

    # Removes all cached detector instances
    def self.reset
      @@instances = {}
      @@ids = []
    end

    # Creates a new detector with the contents of a zip file.
    # The root folder should contain only directories which will become the labels for detection.
    # Each of these directories should contain only a images corresponding to that label.
    # Zip file structure example:
    #    cat/
    #      garfield.jpg
    #      nermal.png
    #    dog/
    #      odie.tiff
    # @note Max 1 GB zip file upload.
    # @param zip_file      [String]     Path to zip file containing the images to be used in the detector creation
    # @param name          [String]     The detector's display name
    # @param detector_type [String]     Options: "general", "face_detector", or "facial_characteristics"
    # @return [Detector]
    def self.create(zip_file, name, detector_type='general')
      case zip_file
      when String
        file = File.new(zip_file, 'rb')
      when File
        file = zip_file
      else
        err_msg = 'First argument must be a zip file of the image folders, or a string of the path to the file'
        raise Error::InvalidQueryError.new(err_msg)
      end
      params = {
        file: file,
        name: name,
        detector_type: detector_type
      }
      response = Matroid.post('detectors', params)
      id = response['detector_id']
      find_by_id(id)
    end

    def initialize(params)
      update_params(params)
    end

    # Detector attributes in a nicely printed format for viewing
    def info
      puts JSON.pretty_generate(to_hash)
    end

    # Detector attributes as a hash
    # @return [Hash]
    def to_hash
      instance_variables.each_with_object(Hash.new(0)) do |element, hash|
        hash["#{element}".delete("@").to_sym] = instance_variable_get(element)
      end
    end

    # Submits detector instance for training
    # @note
    #   Fails if detector is not qualified to be trained.
    def train
      raise Error::APIError.new("This detector is already trained.") if is_trained?
      response = Matroid.post("detectors/#{@id}/finalize")
      response['detector']
    end

    # @return [Boolean]
    def is_trained?
      @state == 'trained'
    end

    # Updates the the detector data. Used when training to see the detector training progress.
    # @return [Detector]
    def update
      self.class.find_by_id(@id)
    end

    # Submits an image file via url to be classified with the detector
    # @param url [String] Url for image file
    # @return Hash containing the classification data.
    # @example
    #     det = Matroid::Detector.find_by_id "5893f98530c1c00d0063835b"
    #     det.classify_image_url "https://www.allaboutbirds.org/guide/PHOTO/LARGE/common_tern_donnalynn.jpg"
    #     ### returns hash of results ###
    #     # {
    #     #   "results": [
    #     #     {
    #     #       "file": {
    #     #         "name": "image1.png",
    #     #         "url": "https://myimages.1.png",
    #     #         "thumbUrl": "https://myimages.1_t.png",
    #     #         "filetype": "image/png"
    #     #       },
    #     #       "predictions": [
    #     #         {
    #     #           "bbox": {
    #     #             "left": 0.7533333333333333,
    #     #             "top": 0.4504347826086956,
    #     #             "height": 0.21565217391304348,
    #     #             "aspectRatio": 1.0434782608695652
    #     #           },
    #     #           "labels": {
    #     #             "cat face": 0.7078468322753906,
    #     #             "dog face": 0.29215322732925415
    #     #           }
    #     #         },
    #     #         {
    #     #           "bbox": {
    #     #             "left": 0.4533333333333333,
    #     #             "top": 0.6417391304347826,
    #     #             "width": 0.20833333333333334,
    #     #             "height": 0.21739130434782608,
    #     #             "aspectRatio": 1.0434782608695652
    #     #           },
    #     #           "labels": {
    #     #             "cat face": 0.75759859402753906,
    #     #             "dog face": 0.45895322732925415
    #     #           }
    #     #         }, {
    #     #           ...
    #     #         }
    #     #       ]
    #     #     }
    #     #   ]
    #     # }
    def classify_image_url(url)
      classify('image', url: url)
    end

    # Submits an image file via url to be classified with the detector
    # @param url [String] Url for image file
    # @return Hash containing the classification data see {#classify_image_url }
    # @example
    #     det = Matroid::Detector.find_by_id "5893f98530c1c00d0063835b"
    #     det.classify_image_file "path/to/file.jpg"
    def classify_image_file(file_path)
      size_err = "Individual file size must be under #{IMAGE_FILE_SIZE_LIMIT / 1024 / 1024}MB"
      raise Error::InvalidQueryError.new(size_err) if File.size(file_path) > IMAGE_FILE_SIZE_LIMIT
      classify('image', file: File.new(file_path, 'rb'))
    end

    # The plural of {#classify_image_file}
    # @param file_paths [Array<String>] An array of images in the form of paths from the current directory
    # @return Hash containing the classification data
    def classify_image_files(file_paths)
      arg_err = "Error: Argument must be an array of image file paths"
      size_err = "Error: Total batch size must be under #{BATCH_FILE_SIZE_LIMIT / 1024 / 1024}MB"
      raise arg_err unless file_paths.is_a?(Array)
      batch_size = file_paths.inject(0){ |sum, file| sum + File.size(file) }
      raise size_err unless batch_size < BATCH_FILE_SIZE_LIMIT
      files = file_paths.map{ |file_path| ['file', File.new(file_path, 'rb')] }

      url = "#{Matroid.base_api_uri}detectors/#{@id}/classify_image"

      client = HTTPClient.new
      response = client.post(url, body: files, header: {'Authorization' => Matroid.token.authorization_header})
      Matroid.parse_response(response)
      # Matroid.post("detectors/#{@id}/classify_image", files) # responds with 'request entity too large' for some reason
    end

    # Submits a video file via url to be classified with the detector
    # @param url [String] Url for video file
    # @return Hash containing the registered video's id; ex: { "video_id" => "58489472ff22bb2d3f95728c" }. Needed for Matroid.get_video_results(video_id)
    def classify_video_url(url)
      classify('video', url: url)
    end

    # Submits a local video file to be classified with the detector
    # @param file_path [String] Path to file
    # @return Hash containing the registered video's id ex: { "video_id" => "58489472ff22bb2d3f95728c" }. Needed for Matroid.get_video_results(video_id)
    def classify_video_file(file_path)
      size_err = "Video file size must be under #{VIDEO_FILE_SIZE_LIMIT / 1024 / 1024}MB"
      raise Error::InvalidQueryError.new(size_err) if File.size(file_path) > VIDEO_FILE_SIZE_LIMIT
      classify('video', file: File.new(file_path, 'rb'))
    end

    # Monitor an existing stream on Matroid with your detector
    # @param stream_id [String] the id for the stream to monitor with the detector
    # @param thresholds [Hash] contains the keys for each label and the score cutoff for a notification. Example: { cat: 0.6, dog: 0.9 }
    # @param options [Hash] contains startTime, endTime [ISO strings], and endpoint [String]. The HTTP endpoint is called whenever there is a detection
    # @return Hash containing the stream_id and monitoring_id
    def monitor_stream(stream_id, thresholds, options = {})
      monitor_err = "Must include stream id"
      raise Error::InvalidQueryError.new(monitor_err) unless stream_id
      params = {
        thresholds: thresholds.to_json
      }
      params = params.merge(options)
      Matroid.post("feeds/#{stream_id}/monitor/#{@id}", params)
    end

    def update_params(params)
      @id = params['id'] if params['id']
      @name = params['name'] if params['name']
      @labels = params['labels'] if params['labels']
      @label_ids = params['label_ids'] if params['label_ids']
      @permission_level = params['permission_level'] if params['permission_level']
      @owner = params['owner'] if params['owner']
      @type = params['type'] if params['type']
      @training = params['training'] if params['training']
      @state = params['state'] if params['state']
      self
    end

    private

    def classify(type, params)
      not_trained_err = "This detector's training is not complete."
      raise Error::InvalidQueryError.new(not_trained_err) unless is_trained?
      Matroid.post("detectors/#{@id}/classify_#{type}", params)
    end

    def self.register(obj)
      id = obj['id']
      @@ids.push(id) if @@instances[id].nil?
      if  @@instances[id].class == Detector
        @@instances[id].update_params(obj)
      else
        @@instances[id] = Detector.new(obj)
      end
    end

  end
end
