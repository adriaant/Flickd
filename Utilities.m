/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#include "Utilities.h"
#include <SystemConfiguration/SCNetworkReachability.h>

BOOL isOnline(NSString *urlStr) { 
	NSString	*host;
	NSString	*encStr = (NSString*)CFURLCreateStringByAddingPercentEscapes(
						NULL, (CFStringRef)urlStr, (CFStringRef)@"#%", NULL,
						CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
	NSURL		*url = [NSURL URLWithString:encStr];

	[encStr release];	
	if (url == nil) return NO;
	
	host = [url host];

    SCNetworkReachabilityFlags	flags;
    SCNetworkReachabilityRef	reachability = SCNetworkReachabilityCreateWithName(NULL, [host UTF8String]);
	BOOL gotFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
    
	CFRelease(reachability);
    if (!gotFlags) {
        return NO;
    }

    // kSCNetworkReachabilityFlagsReachable indicates that the specified nodename or address can
	// be reached using the current network configuration.
	BOOL isReachable = flags & kSCNetworkReachabilityFlagsReachable;
	
	// This flag indicates that the specified nodename or address can
	// be reached using the current network configuration, but a
	// connection must first be established.
	//
	// As an example, this status would be returned for a dialup
	// connection that was not currently active, but could handle
	// network traffic for the target system.
	//
	// If the flag is false, we don't have a connection. But because CFNetwork
    // automatically attempts to bring up a WWAN connection, if the WWAN reachability
    // flag is present, a connection is not required.
	BOOL noConnectionRequired = !(flags & kSCNetworkReachabilityFlagsConnectionRequired);
	if ((flags & kSCNetworkReachabilityFlagsIsWWAN)) {
		noConnectionRequired = YES;
	}
	
	return (isReachable && noConnectionRequired) ? YES : NO;
}

void showErrorAlert(id delegate, NSString *title, NSString *message) {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title 
				message:message
			   delegate:delegate 
	  cancelButtonTitle:@"OK" 
	  otherButtonTitles:nil];
	[alert show];
	[alert release];
}

NSString* createUUID(void) {
    CFUUIDRef   uuid = CFUUIDCreate(NULL);
    CFStringRef uuidRef = CFUUIDCreateString(NULL, uuid);
	NSString	*uuidStr = [[NSString alloc] initWithString:(NSString*)uuidRef];
    CFRelease(uuidRef);
    CFRelease(uuid);
	return [uuidStr autorelease];
}
