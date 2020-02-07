# AvoStateOfTracking

[![CI Status](https://img.shields.io/travis/AlexeyVerein/AvoStateOfTracking.svg?style=flat)](https://travis-ci.org/AlexeyVerein/AvoStateOfTracking)
[![Version](https://img.shields.io/cocoapods/v/AvoStateOfTracking.svg?style=flat)](https://cocoapods.org/pods/AvoStateOfTracking)
[![License](https://img.shields.io/cocoapods/l/AvoStateOfTracking.svg?style=flat)](https://cocoapods.org/pods/AvoStateOfTracking)
[![Platform](https://img.shields.io/cocoapods/p/AvoStateOfTracking.svg?style=flat)](https://cocoapods.org/pods/AvoStateOfTracking)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AvoStateOfTracking is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AvoStateOfTracking'
```

# Initializing

    AvoStateOfTracking *avoSot = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey"];
    
# Enabling logs

    [AvoStateOfTracking setLogging:YES];

# Sending event schemas

Whenever you send tracking event post it to Avo State of Tracking.

    [avoSot trackSchemaFromEvent:@"Event Name" eventParams:(NSDictionary *)eventParams];

## Author

Avo (https://www.avo.app), friends@avo.app

## License

AvoStateOfTracking is available under the MIT license. See the LICENSE file for more info.
