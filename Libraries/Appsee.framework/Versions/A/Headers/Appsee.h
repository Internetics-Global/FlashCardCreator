//
//  Appsee.h
//  Appsee
//
//  Copyright (c) 2012 Shift 6 Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/********************************************************************************************
    Appsee SDK.
    To use, simply call 'start:' in your 'applicationDidFinishLaunching:withOptions:' method. 
 *******************************************************************************************/

@interface Appsee: NSObject

/***************
 General Control
 **************/

/** Starts recording screen and user gestures. This method should only be called once.
    Recording will stop (and video will be uploaded) when app is in the background.
    A new session will start when the app is returned from background.
 @param apiKey The application-specific API key from (available in your Appsee dashboard).
 */
+(void)start:(NSString*) apiKey;

/** Stops the current session. Usually, this method shouldn't be called unless you explictly want to stop recording.  
 */
+(void)stop;

/** Stops the current session and uploads it immediately (in the background). Usually, this method shouldn't be called unless you explictly want 
    to stop recording and force uploading at some point in your app, before the user minimizes it.
 */
+(void)stopAndUpload;

/** Pause recording of the video. Note: user gestures will still be recorded. To resume, call 'resume'.
 */
+(void)pause;

/** Resume recording of the video.
 */
+(void)resume;

/** Enable Appsee event-logging to NSLog.
 @param log YES to turn on debug logging, NO to turn them off.
 */
+(void)setDebugToNSLog:(BOOL)log;

/***************************
 Application Events & Views
 **************************/

/** Add a timed application event (such as: user reached a specific level or screen). 
 @param eventName The name of the event (ie: "WelcomeScreen").
 */
+(void)addEvent:(NSString*)eventName;

/** Add a timed application event (such as: user reached a specific level or screen) along with a parameter. 
 @param eventName The name of the event (ie: "Level").
 @param parameter A parameter describing the the event (ie: "3").
 */
+(void)addEvent:(NSString*)eventName withParameter:(NSString*)parameter;

/** Mark the appearance starting time of a screen.
 This method should be usually called from the viewDidAppear: method.
 @param screenName The name of the screen (ie: "WelcomeScreen").
 */
+(void)startScreen:(NSString*)screenName;

/************************
 Setting User Information
 ************************/
 
/** Set the app's user ID. 
 @param userID The application-specific user identifier.
 */
+(void)setUserID:(NSString*)userID;

/** Set the user's location. 
 @param latitude Latitude.
 @param longitude Longitude.
 @param horizontalAccuracy Horizontal Accuracy.
 @param verticalAccuracy Vertical Accuracy.
 */
+(void)setLocation:(double)latitude longitude:(double)longitude horizontalAccuracy:(float)horizontalAccuracy verticalAccuracy:(float)verticalAccuracy;

/****************
 Privacy Control
 ****************/
 
/** Mark a view as sensitive, to ensure it is not displayed in videos. 
 * Note that password fields are marked as sensitive by default.
 @param view A UIView that contains sensitive information.
 */
+(void)markViewAsSensitive:(UIView*)view;



@end
