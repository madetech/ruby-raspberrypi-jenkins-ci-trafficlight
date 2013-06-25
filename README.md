#Jenkins CI Traffic Light for Raspberry Pi

Once a complete circuit has been made this script that will will emulate a traffic light for your overall jenkins build status, Green for all passed, Amber (flashing) for building and Red for a failure.

Currently the only authorisation method supported is basic http authentication.

###Prerequisites
* Raspbian “wheezy” > 2013-05-25
* Ruby == 1.9.3
* Rubygems

If you don't have Ruby installed on your Pi follow this [guide](http://elinux.org/RPi_Ruby)

###Setup
* `gem install bundler` if you don't already have it installed
* `bundle install`
* Rename sample_config.rb to config.rb
* Enter your creditials
* Set GPiO pin numbers
* Setup circuit
* run `ruby jenkins.rb`

###Circuit Diagram
![Jenkins CI Traffic Light for Raspberry Pi Circuit Diagram](https://raw.github.com/madebymade/ruby-raspberrypi-jenkins-ci-trafficlight/master/circuit.png)

###License
Licensed under [New BSD License](https://github.com/madebymade/jquery-navobile/blob/master/license.txt)

###To Do
- [ ] Add more auth methods
