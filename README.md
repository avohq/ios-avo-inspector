# AvoInspector

[![Version](https://img.shields.io/cocoapods/v/AvoInspector.svg?style=flat)](https://cocoapods.org/pods/AvoInspector)
[![License](https://img.shields.io/cocoapods/l/AvoInspector.svg?style=flat)](https://cocoapods.org/pods/AvoInspector)
[![Platform](https://img.shields.io/cocoapods/p/AvoInspector.svg?style=flat)](https://cocoapods.org/pods/AvoInspector)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AvoInspector is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AvoInspector'
```

# Avo documentation

This is a quick start guide. 
For more information about the Datascope project please read [Avo documentation](https://www.avo.app/docs/datascope/avo-inspector/ios).

# Initializing

Obtain the API key at [Avo.app](https://www.avo.app/welcome) 

Obj-C

    AvoInspector *avoInspector = [[AvoInspector alloc] initWithApiKey:@"apiKey" isDev: devFlag];
        
Swift

    let avoInspector = AvoInspector(apiKey: "apiKey", isDev: devFlag)
    
# Enabling logs

Logs are enabled by default in the dev mode and disabled in prod mode based on the init flag.

Obj-C

    [AvoInspector setLogging:YES];
        
Swift

    AvoInspector.setLogging(true)

# Sending event schemas

Whenever you send tracking event call one of the following methods:
Read more in the [Avo documentation](https://www.avo.app/docs/datascope/avo-inspector/ios#event-tracking) 

### 1.

This methods gets actual tracking event parameters, extracts schema automatically and sends it to Avo Datascope.
It is the easiest way to use the library, just call this method at the same place you call your analytics tools' track methods with the same parameters.

Obj-C

    [avoInspector trackSchemaFromEvent:@"Event Name" eventParams:@{@"id": @"sdf-334fsg-334f", @"number": @41}];
    
Swift
    
    avoInspector.trackSchema(fromEvent: "Event Name", eventParams: ["id": "sdf-334fsg-334f", "number": 41])
    
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

    [AvoInspector setBatchSize:15];
    [AvoInspector setBatchFlustSeconds:10];
    
Swift
    
    AvoInspector.setBatchSize(15)
    AvoInspector.setBatchFlustSeconds(10)

## Author

Avo (https://www.avo.app), friends@avo.app

## License

AvoInspector is available under the MIT license. See the LICENSE file for more info.
