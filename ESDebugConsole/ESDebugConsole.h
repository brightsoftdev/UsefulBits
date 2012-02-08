//
//  ESDebugConsole.h
//
//  Copyright Doug Russell 2012. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

extern NSString *const kESDebugConsoleAllLogsKey;

@interface ESDebugConsole : NSObject
{
@private
	// iOS Support
	id _window;
	id _popoverController;
	id _gestureRecognizer;
	id _navigationController;
	CGSize _consoleSizeInPopover;
	// iOS Mail Support
	id _recipients;
	id _subject;
	id _message;
	id _attachment;
}

/**
 * Shared instance of debug console overlay
 */
+ (id)sharedDebugConsole;

/**
 * Dictionary containing arrays of ESConsoleEntry objects
 * Keyed by application identifier.
 * Key kESDebugConsoleAllLogsKey returns an array of console entries for all apps.
 */
+ (NSDictionary *)getConsole;

@end
