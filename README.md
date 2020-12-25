# AvoInspector

[![Version](https://img.shields.io/cocoapods/v/AvoInspector.svg?style=flat)](https://cocoapods.org/pods/AvoInspector)
[![License](https://img.shields.io/cocoapods/l/AvoInspector.svg?style=flat)](https://cocoapods.org/pods/AvoInspector)
[![Platform](https://img.shields.io/cocoapods/p/AvoInspector.svg?style=flat)](https://cocoapods.org/pods/AvoInspector)

# Avo documentation

This is a quick start guide. 
For more information about the Inspector project please read [Avo documentation](https://www.avo.app/docs/implementation/inspector/sdk/ios).

# Installation

AvoInspector is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AvoInspector'
```

The latest version can be found in GitHub releases tab.

# Import

Obj-C
```objectivec
#import <AvoInspector/AvoInspector.h>
```
Swift
```swift
import AvoInspector
```

# Initialization

Obtain the API key at [Avo.app](https://www.avo.app/welcome) 


Obj-C
```objectivec
AvoInspector *avoInspector = [[AvoInspector alloc] initWithApiKey:@"apiKey" env: AvoInspectorEnvDev];
```       
Swift
```swift
let avoInspector = AvoInspector(apiKey: "apiKey", env: AvoInspectorEnv.dev)
```
# Enabling logs

Logs are enabled by default in the dev mode and disabled in prod mode based on the init flag.

Obj-C
```objectivec
[AvoInspector setLogging:YES];
```

Swift
```swift
AvoInspector.setLogging(true)
```

# Integrating with Avo Functions (Avo generated code)

The setup is lightweight and is covered [in this guide](https://www.avo.app/docs/implementation/start-using-inspector-with-avo-functions).

Every event sent with Avo Function after this integration will automatically be sent to the Avo Inspector.

# Sending event schemas for events reported outside of Avo Functions

Whenever you send tracking event call one of the following methods:

Read more in the [Avo documentation](https://www.avo.app/docs/implementation/devs-101#inspecting-events)

### 1.

This methods get actual tracking event parameters, extract schema automatically and send it to the Avo Inspector backend.
It is the easiest way to use the library, just call this method at the same place you call your analytics tools' track methods with the same parameters.

Obj-C
```objectivec
[avoInspector trackSchemaFromEvent:@"Event Name" eventParams:@{@"id": @"sdf-334fsg-334f", @"number": @41}];
```

Swift
```swift
avoInspector.trackSchema(fromEvent: "Event Name", eventParams: ["id": "sdf-334fsg-334f", "number": 41])
```
### 2.

If you prefer to extract data schema manually you would use this method.

Obj-C
```objectivec
[avoInspector trackSchema:@"Event Name" eventSchema:@{@"id": [[AvoString alloc] init], @"number": [[AvoInt alloc] init]}];
```

Swift
```swift
avoInspector.trackSchema("Event Name", eventSchema: ["id": AvoString(), "number": AvoInt()])
```
# Extracting event schema manually

Obj-C
```objectivec
NSDictionary * schema = [avoInspector extractSchema:@{@"id": @"sdf-334fsg-334f", @"number": @41}];
```

Swift
```swift
let schema = avoInspector.extractSchema(["id": "sdf-334fsg-334f", "number": 41])
```

# Using the Visual Inspector

Visual Inspector is enabled in development and staging environments by default.

## Show

Obj-C
```objectivec
[avoInspector showVisualInspector:Bar]; // or Bubble
```

Swift
```swift
avoInspector.show(AvoVisualInspectorType.Bar) // or AvoVisualInspectorType.Bubble
```

## Hide

Obj-C
```objectivec
[avoInspector hideVisualInspector];
```

Swift
```swift
avoInspector.hideVisualInspector()
```

## Advanced usage

You can get an instance of `AnalyticsDebugger` with the following method. 

Obj-C
```objectivec
[avoInspector getVisualInspector];
```

Swift
```swift
avoInspector.getVisualInspector()
```

See more about `AnalyticsDebugger` in [GitHub repo](https://github.com/avohq/ios-analytics-debugger)

# Batching control

In order to ensure our SDK doesn't have a large impact on performance or battery life it supports event schemas batching.

Default batch size is 30 and default batch flush timeout is 30 seconds.
In debug mode default batch flush timeout is 1 second, i.e. the SDK batches schemas of events sent withing one second.

Obj-C
```objectivec
[AvoInspector setBatchSize:15];
[AvoInspector setBatchFlushSeconds:10];
```

Swift
```swift
AvoInspector.setBatchSize(15)
AvoInspector.setBatchFlushSeconds(10)
```
    
# Example App

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Author

Avo (https://www.avo.app), friends@avo.app

## License

AvoInspector is available under the MIT license. See the LICENSE file for more info.
