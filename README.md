## Features
* API endpoint coverage
* Automatic authenticated work flow
* [Full documentation](http://www.rubydoc.info/github/matroid/matroid-ruby)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'matroid'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install matroid

## Usage
This api wrapper allows you to easily create and use Matroid detectors for classifying various media.
It is designed to allow you to use detectors without any notion of the API.

Check the [documentation](http://www.rubydoc.info/github/matroid/matroid-ruby) for the complete reference of available methods.

# Authenticate your session
The Matroid API relies on the use of access tokens The easiest way to automatically
authenticate your usage and handle access tokens is to declare `MATROID_CLIENT_ID`
and `MATROID_CLIENT_SECRET` in your environment. For example, place the following in your
`.env` file:
```
MATROID_CLIENT_ID=XXXXXXXXXXXXXXXXXXX
MATROID_CLIENT_SECRET=XXXXXXXXXXXXXXXXXXXXXXXXXXX
```
Also, you may call `Matroid.authenticate(MATROID_CLIENT_ID, MATROID_CLIENT_SECRET)` before
any other methods and the token will be stored in the instance and refreshed as needed.

# Example API usage
```
require 'matroid'

MATROID_CLIENT_ID=XXXXXXXXXXXXXXXXXXX
MATROID_CLIENT_SECRET=XXXXXXXXXXXXXXXXXXXXXXXXXXX

Matroid.authenticate(MATROID_CLIENT_ID, MATROID_CLIENT_SECRET)

# Check user account info like Matroid Credits balance
Matroid.account_info


# Get detector by id
detector = Matroid::Detector.find_by_id('5893f98530c1c00d0063835b')

# Get detector details
detector.info #=> Hash of all the details (or you can get them separately as below)
detector.id #=> "5893f98530c1c00d0063835b"
detector.name #=> "My cool detector"
detector.state #=> "trained"
detector.labels #=> ["label 1", "label 2", ...]
detector.permission_level #=> "private"
detector.owner #=> true
detector.training #=> "successful"
detector.detector_type #=> "general"

# Create a detector
detector = Matroid::Detector.create('PATH/TO/ZIP/FILE', 'My awesome detector', 'general') # uploads labels and images
detector.id #=> "XxXxXxXxXxXxXxXxXxXxXxXxXxXxXx"
detector.name #=> "My awesome detector"
detector.state #=> "pending"
detector.labels #=> ["label 1", "label 2", ...]
detector.permission_level #=> "private"
detector.owner #=> true
detector.detector_type #=> "general"
detector.train # submits the detector for training
# you can repeatedly call detector.info to get the updates on the training

# Use a detector
detector = Matroid::Detector.find_by_id('5893f98530c1c00d0063835b')

# Classifying an image returns a hash of the detected labels (with probabilities)
# along with bounding box information (if applicable)
detector.classify_image_url('https://www.example.com/images/some_image.jpg')
detector.classify_image_file('PATH/TO/IMAGE/FILE')

# Classifying a video returns a hash { "video_id" => "dfoguhd078yd7dg87dfvsdf7" }
# which can later be used to check on the classification.
# A video takes some time to classify depending on the length and size of the video uploaded.
detector.classify_video_url('https://www.youtube.com/watch?v=0qVOUD76JOg')
detector.classify_video_file('PATH/TO/VIDEO/FILE')

# Call the following repeatedly to check the progress on the video classification results
Matroid.get_video_results('dfoguhd078yd7dg87dfvsdf7') #=> details of timestamps with labels, etc.

```

More functionality coming soon.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
