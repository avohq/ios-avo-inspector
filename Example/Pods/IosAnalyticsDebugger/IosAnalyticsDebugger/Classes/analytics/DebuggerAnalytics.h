// Generated by Avo VERSION 56.1.0, PLEASE EDIT WITH CARE


#ifndef DebuggerAnalytics_h
#define DebuggerAnalytics_h

typedef NS_ENUM(NSInteger, AVOEnv) {
  AVOEnvProd = 0,
  AVOEnvDev = 1,
};

@protocol AVOCustomDestination

- (void)make:(AVOEnv)avoEnv;

- (void)logEvent:(nonnull NSString*)eventName withEventProperties:(nonnull NSDictionary*)eventProperties;

- (void)setUserProperties:(nonnull NSString*)userId withUserProperties:(nonnull NSDictionary*)userProperties;

- (void)identify:(nonnull NSString*)userId;

- (void)unidentify;

@end

typedef NS_ENUM(NSInteger, AVOEnumClient) {
  AVOEnumClientNULL = -1,
  AVOEnumClientCloudFunctions = 0,
  AVOEnumClientWeb = 1,
  AVOEnumClientLandingPage = 2,
  AVOEnumClientCli = 3,
  AVOEnumClientWebDebugger = 4,
  AVOEnumClientAndroidDebugger = 5,
  AVOEnumClientIosDebugger = 6,
  AVOEnumClientReactNativeDebuggerIos = 7,
  AVOEnumClientReactNativeDebuggerAndroid = 8
};

@interface DebuggerAnalytics : NSObject

+ (void)initAvoWithEnv:(AVOEnv)env
  client:(AVOEnumClient)client
  version:(nullable NSString *)version
  customNodeJsDestination:(nonnull id<AVOCustomDestination>)customNodeJsDestination;

+ (void)initAvoWithEnv:(AVOEnv)env
  client:(AVOEnumClient)client
  version:(nullable NSString *)version
  customNodeJsDestination:(nonnull id<AVOCustomDestination>)customNodeJsDestination
  strict:(BOOL)strict;

+ (void)initAvoWithEnv:(AVOEnv)env
  client:(AVOEnumClient)client
  version:(nullable NSString *)version
  customNodeJsDestination:(nonnull id<AVOCustomDestination>)customNodeJsDestination
  debugger:(nonnull NSObject *)debugger;

+ (void)initAvoWithEnv:(AVOEnv)env
  client:(AVOEnumClient)client
  version:(nullable NSString *)version
  customNodeJsDestination:(nonnull id<AVOCustomDestination>)customNodeJsDestination
  strict:(BOOL)strict
  debugger:(nonnull NSObject *)debugger;

+ (void)setSystemPropertiesWithClient:(AVOEnumClient)client
  version:(nullable NSString *)version;

/**
 * Debugger Started: Sent when the web debugger is started.
 * 
 * @param frameLocation Describes from where the debugger was started.
 * @param schemaId The ID of the schema that this event is related to.
 *
 * @see <a href="https://www.avo.app/schemas/fwtXqAc0fCLy7b7oGW40/branches/LowQacyet/events/Od3PNKHK1">Debugger Started</a>
 */
+ (void)debuggerStartedWithFrameLocation:(nullable NSString *)frameLocation
  schemaId:(nonnull NSString *)schemaId;

@end

#endif
