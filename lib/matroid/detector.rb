# size limit constants
IMAGE_FILE_SIZE_LIMIT = 50 * 1024 * 1024
VIDEO_FILE_SIZE_LIMIT = 300 * 1024 * 1024
BATCH_FILE_SIZE_LIMIT = 50 * 1024 * 1024
ZIP_FILE_SIZE_LIMIT   = 300 * 1024 * 1024
module Matroid


  # Represents a Matroid detector
  # @attr [String]          id                Detector id
  # @attr [String]          name              Detector name
  # @attr [Array<String>]   labels
  # @attr [String]          permission_level  'private', 'readonly', 'open', 'stock'
  # @attr [Bool]            owner             is the current authicated user the owner
  class Detector
    # HASH { <id> => Detector }
    @@detectors = {}
    @@detector_ids = []

    attr_reader :id, :name, :labels, :permission_level, :owner, :training,
                :detector_type, :state

    # Looks up the detector by id
    # @note The detector must either be published or created by the current authenticated user.
    # @param detector_id [String]
    # @return [Detector] Returns the detector instance.
    def self.find_by_id(detector_id)
      # update list if not in the list
      refresh if @@detectors[detector_id].nil?

      # if it's pending and not registered
      fetch(detector_id) if @@detectors[detector_id].nil?
      detector = @@detectors[detector_id]

      # should already raise error before this
      err_msg = "Couldn't find detector"
      raise Error::InvalidQueryError.new(err_msg) if detector.nil?
      get_or_make_detector(detector)
    end

    # Looks up the detector by matching fields.
    # :label and :name accept a string or regular expression.
    # @example
    #   Matroid::Detector.find(label: 'cat', state: 'trained')
    # @example
    #   Matroid::Detector.find(name: /cat/)
    # @example
    #   Matroid::Detector.find(label: 'puppy').first.id
    # @note The detector must either be published or created by the current authenticated user.
    # @return [Array<Detector>] Returns the detector instances that match the query.
    def self.find(args)
      raise Error::InvalidQueryError.new('Argument must be a hash.') unless args.class == Hash
      refresh
      matches = @@detector_ids.inject([]) do |arr, id|
        det = self.detector_json_from_id(id)
        not_match = args.keys.any? do |key|
          val = args[key]
          case key.to_s
          when 'label'
            case val
            when String
              !det['labels'].include?(val)
            when Regexp
              !det['labels'].any?{ |w| w.match(val) }
            else
              raise Error::InvalidQueryError.new('The value for the key :label must be a String or Regexp.')
            end
          when 'name'
            case val
            when String
              !det['name'] == val
            when Regexp
              !det['name'].match(val)
            else
              raise Error::InvalidQueryError.new('The value for the key :name must be a String or Regexp.')
            end
          else
            det[key] != args[key]
          end
        end

        not_match ? arr : arr << get_or_make_detector(det)
      end

      matches
    end

    # @return [Array] List of detectors as hashes.
    def self.list
      refresh
      @@detector_ids.inject([]){ |arr, id| arr << @@detectors[id] }
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
      response = Matroid.post('/detectors', params)
      id = response['detector_id']
      params = {
        'detector_id' => id,
        'human_name' => name,
        'owner' => true
      }
      register_detector(params)
      detector = find_by_id(id)
      detector.update
    end

    def initialize(params)
      update_params(params)
    end

    # @return Hash of detector info
    def info
      update
      {
        'id' => @id,
        'name' => @name,
        'labels' => @labels,
        'permission_level' => @permission_level,
        'owner' => @owner,
        'training' => @training,
        'detector_type' => @detector_type,
        'state' => @state
      }
    end

    # Submits detector instance for training
    # @note
    #   Fails if detector is not qualified to be trained.
    def train
      raise Error::APIError.new('This detector has incomplete training.') unless is_trained?
      response = Matroid.post("/detectors/#{@id}/finalize")
      response['detector']
    end

    # @return [Boolean]
    def is_trained?
      @state == 'trained'
    end

    # Updates the the detector data. Used when training to see the detector training progress.
    # @return [Detector]
    def update
      self.class.fetch(@id)
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
    # @return Hash containing the classification data.
    # @example
    #     det = Matroid::Detector.find_by_id "5893f98530c1c00d0063835b"
    #     det.classify_image_file "https://www.allaboutbirds.org/guide/PHOTO/LARGE/common_tern_donnalynn.jpg"
    #     ### return results are the same as {#classify_image_url }
    def classify_image_file(file_path)
      size_err = "Individual file size must be under #{IMAGE_FILE_SIZE_LIMIT / 1024 / 1024}MB"
      raise Error::InvalidQueryError.new(size_err) if File.size(file_path) > IMAGE_FILE_SIZE_LIMIT
      classify('image', file: File.new(file_path, 'rb'))
    end

    # def classify_image_files(file_paths)
    #   arg_err = "Error: Argument must be an array of image file paths"
    #   size_err = "Error: Total batch size must be under #{BATCH_FILE_SIZE_LIMIT / 1024 / 1024}MB"
    #   raise arg_err unless file_paths.is_a?(Array)
    #   batch_size = file_paths.inject(0){ |sum, file| sum + File.size(file) }
    #   raise err_msg unless batch_size < BATCH_FILE_SIZE_LIMIT
    #   files = file_paths.map{ |file_path| [File.new(file_path, 'rb')] }
    #   classify('image', files)
    # end

    # Submits a video file via url to be classified with the detector
    # @param url [String] Url for video file
    # @return Hash containing the registered video's id ex: { "video_id" => "58489472ff22bb2d3f95728c" }. Needed for Matroid.get_video_results(video_id)
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

    private

    def classify(type, params)
      not_trained_err = "This detector's training is not complete."
      raise Error::InvalidQueryError.new(not_trained_err) unless is_trained?
      Matroid.post("/detectors/#{@id}/classify_#{type}", params)
    end

    def self.get_trained_detectors
      # assumes no detectors were deleted
      Matroid.get '/detectors'
    end

    def self.fetch(id)
      response = Matroid.get('/detectors/' + id)
      params =  response['detector']
      params['detector_id'] = id
      register_detector(params)
      get_or_make_detector(id)
    end

    def self.get_or_make_detector(obj)
      case obj
      when Detector
        # already a detector
        return obj
      when Hash
        # raw detector info
        id = obj['id']
        return @@detectors[id] if id &&  @@detectors[id].class == Detector
        detector = Detector.new(obj)
        @@detectors[id] = detector
        return detector
      when String
        # assume this is an id
        id = obj
        return get_or_make_detector(@@detectors[id])
      end

      nil
    end

    def self.refresh
      detectors = get_trained_detectors
      detectors.each do |detector|
        id = detector['detector_id']
        if @@detectors[id].nil?
          detector['training'] = 'successful'
          detector['state'] = 'trained'
          @@detectors[id] = detector
          @@detector_ids.push(id)
        end
      end
      nil
    end

    def self.register_detector(obj)
      det_id = obj['detector_id'] || obj['id']
      @@detector_ids.push(det_id) if @@detectors[det_id].nil?
      case  @@detectors[det_id]
      when Detector
        @@detectors[det_id].update_params(obj)
      else
        @@detectors[det_id] = obj
      end
    end

    def self.detector_json_from_id(id)
      case  @@detectors[id]
      when Detector
        @@detectors[id].info
      else
        @@detectors[id]
      end
    end

    def update_params(params)
       @id = params['detector_id'] if params['detector_id']
       @name = params['human_name'] if params['human_name']
       @labels = params['labels'].map do |label|
         case label
         when String
           label
         when Hash
           label['name']
         end
       end if params['labels'].is_a?(Array)
       @permission_level = params['permission_level'] if params['permission_level']
       @owner = params['owner'] if params['owner']
       @detector_type = params['detector_type'] if params['detector_type']
       @training = params['training'] if params['training']
       @state = params['state'] if params['state']
       nil
    end
  end
end
