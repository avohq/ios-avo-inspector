# AvoStateOfTracking

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

# Avo documentation

Here you can find short hands-on integration guide. 
For more info about the Datascope project please read [Avo documentation](https://www.avo.app/docs/datascope/state-of-tracking/ios) 

# Initializing

Obtain the API key at [Avo.app](https://www.avo.app/welcome) 

Obj-C

    AvoStateOfTracking *avoSot = [[AvoStateOfTracking alloc] initWithApiKey:@"apiKey" isDev: devFlag];
        
Swift

    let avoSot = AvoStateOfTracking(apiKey: "apiKey", isDev: devFlag)
    
# Enabling logs

Logs are enabled by default in the dev mode and disabled in prod mode based on the init flag.

Obj-C

    [AvoStateOfTracking setLogging:YES];
        
Swift

    AvoStateOfTracking.setLogging(true)

# Sending event schemas

Whenever you send tracking event call one of the following methods:
Read more in the [Avo documentation](https://www.avo.app/docs/datascope/state-of-tracking/ios#event-tracking) 

### 1.

This methods gets actual tracking event parameters, extracts schema automatically and sends it to Avo Datascope.
This is the easiest way to use the library, just call ,this method at the same place you call your analytics tools' track method.

Obj-C

    [avoSot trackSchemaFromEvent:@"Event Name" eventParams:@{@"id": @"sdf-334fsg-334f", @"number": @41}];
    
Swift
    
    avoSot.trackSchema(fromEvent: "Event Name", eventParams: ["id": "sdf-334fsg-334f", "number": 41])
    
### 2.

If you prefer to extract data schema manually you would use this method.

Obj-C

    [avoSot trackSchema:@"Event Name" eventSchema:@{@"id": [[AvoString alloc] init], @"number": [[AvoInt alloc] init]}];
    
Swift

    avoSot.trackSchema("Event Name", eventSchema: ["id": AvoString(), "number": AvoInt()])

# Extract event schema manually

Obj-C

    NSDictionary * schema = [avoSot extractSchema:@{@"id": @"sdf-334fsg-334f", @"number": @41}];
    
Swift
    
    let schema = avoSot.extractSchema(["id": "sdf-334fsg-334f", "number": 41])
    
# Batching control

In order to ensure our SDK doesn't have a large impact on performance or battery life it supports event schemas batching.

Default batch size is 30 and default batch flust timeout is 30 seconds.
In debug mode default batch size is 1, i.e. every event schema is sent to the server as soon as it is reported.

Obj-C

    [AvoStateOfTracking setBatchSize:15];
    [AvoStateOfTracking setBatchFlustSeconds:10];
    
Swift
    
    AvoStateOfTracking.setBatchSize(15)
    AvoStateOfTracking.setBatchFlustSeconds(10)

## Author

Avo (https://www.avo.app), friends@avo.app

## License

AvoStateOfTracking is available under the MIT license. See the LICENSE file for more info.
