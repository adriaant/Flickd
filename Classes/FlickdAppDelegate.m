/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "FlickdAppDelegate.h"

@interface FlickdAppDelegate (Private)
- (BOOL)outdatedSystem;
- (void)loadUserInterface;
@end

@implementation FlickdAppDelegate

@synthesize window, navController, mediaController;

/**
 * Easy access to this app delegate from other controllers.
 */
+ (FlickdAppDelegate*)sharedAppDelegate {
    return (FlickdAppDelegate*)[UIApplication sharedApplication].delegate;
}

/**
 * Application did finish launching. Check system version and camera,
 * then load interface if we're good to go.
 */
- (void)applicationDidFinishLaunching:(UIApplication*)application {
	if ([self outdatedSystem]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Outdated System" message:@"This app only supports iPhone system version 4.2 or higher." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"This app requires the camera to be available." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	} else {
		[self loadUserInterface];
	}
	[window makeKeyAndVisible];
}

/**
 * This app will only run on 4.2 or later.
 */
- (BOOL)outdatedSystem {
	NSString *os_version = [[UIDevice currentDevice] systemVersion];
	NSString *main_version = [os_version substringToIndex:1];
	NSUInteger num = [main_version intValue];
	return (num < 4);
}

/**
 * Dispose of allocated storage.
 */
- (void)dealloc {
	[mediaController release];
	[navController release];
    [window release];
    [super dealloc];
}

/**
 * Load the interface: A navigation controller with MediaController as root view.
 */
- (void)loadUserInterface {
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	
	navController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	navController.navigationBarHidden = YES;

	[window addSubview:navController.view];
	[mediaController performSelector:@selector(showImagePickerAfterDelay:) withObject:[NSNumber numberWithUnsignedInt:UIImagePickerControllerSourceTypeCamera] afterDelay:0.1];
}

/**
 * We informed the user either that the system is outdated or a camera is missing.
 * Nothing else to do but quit the app...
 */
- (void)alertView:(UIAlertView*)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
	exit(1);
}

@end
