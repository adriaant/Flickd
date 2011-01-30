/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

#import "MediaController.h"
#import "PickerController.h"
#import "WebViewController.h"
#import "MetaViewController.h"

#import "Base58Encoder.h"
#import "OAMutableURLRequest.h"
#import "OAToken.h"
#import "APIKeys.h"

#include "Utilities.h"

@interface MediaController (Private)
- (void)displaySaveProgress;
- (void)showMetaController:(id)sender;
- (NSMutableDictionary*)currentLocation;
- (void)dismissPicker;
- (void)showLibrary:(id)sender;
- (void)cleanupUpload:(NSString*)errorStr;
- (void)notifyViaTwitter:(NSString*)photoID;
@end

@implementation MediaController

@synthesize assetURL, capturedPhoto, capturedVideo, mediaProperties;
@synthesize locationController, pickerController;
@synthesize imageView, flickrObject;

/**
 * View is being loaded. Set up the picker and location controllers.
 */
- (void)viewDidLoad {
	_location = nil;
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	
	PickerController *pc = [[PickerController alloc] initWithDelegate:self];
	pc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	self.pickerController = pc;
	[pc release];
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		NSArray *mediaTypesAllowed = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
		[pickerController setMediaTypes:mediaTypesAllowed];
	}

	self.locationController = [[[LocationController alloc] init] autorelease];
	locationController.delegate = self;
	[locationController.locationManager startUpdatingLocation];
}

/**
 * Support any device rotations.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark -
#pragma mark Image Picker

/**
 * Dismisses picker view and shows status bar
 */
- (void)dismissPicker {
	self.imageView.image = self.capturedPhoto;
	[self dismissModalViewControllerAnimated:NO];
}

/**
 * Show photo library, invoked by navigation controller button.
 */
- (void)showLibrary:(id)sender {
	[self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary animated:YES];
}

/**
 * Delayed invocation chained after a view animation needs to be completed first.
 */
- (void)showImagePickerAfterDelay:(NSNumber*)type {
	[self showImagePicker:[type unsignedIntValue] animated:YES];
}

/**
 * The image picker is being requested for either camera or library mode.
 */
- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType animated:(BOOL)animated {
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
		self.pickerController.sourceType = sourceType;
        [self presentModalViewController:self.pickerController animated:animated];
    }
}

/**
 * Triggered when user clicks the "Library" button or the Cancel button in Library mode, 
 * so here we actually switch the picker controller to the alternative mode.
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController*)picker {
	[self dismissModalViewControllerAnimated:NO];
	if (picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
		[self showImagePicker:UIImagePickerControllerSourceTypeCamera animated:YES];
	} else {
		[self showImagePicker:UIImagePickerControllerSourceTypePhotoLibrary animated:YES];
	}
}

/**
 * The user has either taken a photo or picked one from the library. 
 * If necessary, add the geo location and save the image.
 */
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info {

	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

	self.capturedPhoto = image;
	self.assetURL = [info objectForKey:UIImagePickerControllerReferenceURL]; // if we have a saved image    

	if (assetURL) {
		[self dismissPicker];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(showMetaController:)] autorelease];
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Library" style:UIBarButtonItemStylePlain target:self action:@selector(showLibrary:)] autorelease];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
    } else {
		NSMutableDictionary *metaDict = nil;
		ALAssetsLibrary		*library = [[[ALAssetsLibrary alloc] init] autorelease];
		
		[self displaySaveProgress];
		if ([info objectForKey:UIImagePickerControllerMediaMetadata] != nil) {
			metaDict = [NSMutableDictionary dictionaryWithDictionary:[info objectForKey:UIImagePickerControllerMediaMetadata]];
			NSDictionary *gpsDict = [self currentLocation];
			if ([gpsDict count] > 0) {
				[metaDict setObject:gpsDict forKey:(NSString*)kCGImagePropertyGPSDictionary];
			}
		}
		[library writeImageToSavedPhotosAlbum:[self.capturedPhoto CGImage] metadata:metaDict completionBlock:^(NSURL *newURL, NSError *error) {
			[self closeProgressHud];
			if (error) {
				showErrorAlert(self, @"Error", @"The photo you took could not be saved!");
			} else {
				self.assetURL = newURL;
				[self showMetaController:nil];
			}
		}];
	}
}

#pragma mark -
#pragma mark Alert View Delegate

/**
 * User dismissed an alert, which is shown if a photo couldn't be saved,
 * the network is down, or a photo was uploaded. 
 * We just display the photo library.
 */
- (void)alertView:(UIAlertView*)alert clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (self.modalViewController != nil) {
		[self dismissModalViewControllerAnimated:YES];
	}
	self.imageView.image = nil;
	[self performSelector:@selector(showImagePickerAfterDelay:) withObject:[NSNumber numberWithUnsignedInt:UIImagePickerControllerSourceTypePhotoLibrary] afterDelay:0.5];
}

#pragma mark -
#pragma mark Progress Display

/**
 * Display a HUD that indicates photo saving progress. 
 */
- (void)displaySaveProgress {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
	
	[self dismissPicker];
	[self showProgressHud:@"Saving photo..."];
	
	[UIView commitAnimations];
}

/**
 * Update the HUD's determinate progress value.
 * Called from the Flickr instance.
 */
- (void)setProgress:(float)val {
	if (self.progressHud) {
		[self.progressHud setProgress:val];
	}
}

#pragma mark -
#pragma mark Metadata Editing Controller

/**
 * Returns the controller for editing a photo's meta data (title, tags, etc).
 */
- (void)showMetaController:(id)sender {
	MetaViewController *mvc = [[MetaViewController alloc] initWithDelegate:self];
	mvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self.navigationController pushViewController:mvc animated:YES];
	[mvc release];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

#pragma mark -
#pragma mark Upload

/**
 * Called when the meta data editor has been dismissed by the user,
 * an action that indicates that the user wants to upload the photo.
 * We check if we can access Flickr, if so, display progress and 
 * initiate the actual upload.
 */
- (void)uploadRequested:(NSMutableDictionary*)metaData {
	self.mediaProperties = metaData;
	[self.mediaProperties setObject:self.assetURL forKey:@"Asset"];
	if ([self.mediaProperties objectForKey:@"Title"] == nil) {
		[self.mediaProperties setObject:@"Untitled" forKey:@"Title"];
	}
	
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController popViewControllerAnimated:YES];
	
	if (!isOnline(@"http://flickr.com")) {
		showErrorAlert(nil, @"Error", @"The Flickr server cannot be reached. Please try again later.");
		return;
	}
	
	// display progress hud
	[self showProgressHud:@"Uploading photo..." isDeterminate:YES];
	
	// verify the Flickr token
	[self.flickrObject setSelector:@selector(uploadApproved)];
	[self.flickrObject performSelector:@selector(verifyToken) withObject:nil afterDelay:0.1];
}

/**
 * User dismissed metadata editor but didn't upload.
 * Show photo library instead.
 */
- (void)uploadCancelled {
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController popViewControllerAnimated:YES];
	[self performSelector:@selector(showImagePickerAfterDelay:) withObject:[NSNumber numberWithUnsignedInt:UIImagePickerControllerSourceTypePhotoLibrary] afterDelay:0.5];
}

/**
 * Callback from Flickr after token verification passes.
 */
- (void)uploadApproved {
	[self.flickrObject initiateUpload:self.mediaProperties];
}

/**
 * Callback from Flickr after the upload has completed.
 * Optionally send a message to twitter and inform user of success.
 */
- (void)uploadFinished:(NSString*)photoID {
	NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
	NSString		*tokenStr = [settings stringForKey:@"twitter_token"];
	NSString		*str = [settings stringForKey:@"twitter_option"];

	if (str != nil && [str isEqualToString:@"YES"] && tokenStr != nil) {
		self.progressHud.mode = MBProgressHUDModeIndeterminate;
		[self.progressHud setLabelText:@"Tweeting the photo..."];
		[self performSelector:@selector(notifyViaTwitter:) withObject:photoID afterDelay:0.1];
	} else {
		[self cleanupUpload:nil];
	}
}

/**
 * Called after tweet was sent. 
 * Display notice to user.
 */
- (void)cleanupUpload:(NSString*)errorStr {
	[self closeProgressHud];
	
	NSString *msg;	
	if ( errorStr != nil ) {
		msg = [NSString stringWithFormat:@"Your photo was successfully uploaded to Flickr, but the update to Twitter failed: %@", errorStr];
	} else {
		msg = @"Your photo was successfully uploaded to Flickr!";
	}
	showErrorAlert(self, @"Success", msg);
}

/**
 * Callback from Flickr after upload failed.
 */
- (void)uploadFailed:(NSString*)err {
	[self closeProgressHud];
	showErrorAlert(nil, @"Failure", err);
}

/**
 * Return an instance of Flickr, allocating it if necessary. 
 * The Flickr instance takes care of all Flickr API queries.
 */
- (Flickr*)flickrObject {
	if (flickrObject == nil) {
		flickrObject = [[Flickr alloc] initWithDelegate:self];
	}
	return flickrObject;
}

#pragma mark -
#pragma mark Twitter

/**
 * If configured to tweet the uploaded photo, then create a short flickr url
 * and submit a tweet to Twitter. 
 */
- (void)notifyViaTwitter:(NSString*)photoID {
	NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
	NSString		*tokenStr = [settings stringForKey:@"twitter_token"];
	NSString		*photoTitle = [self.mediaProperties objectForKey:@"Title"];
	NSString		*escTitle = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)photoTitle, NULL, (CFStringRef)@";/?:@&=+$,", kCFStringEncodingUTF8);
	NSString		*encodedID = [Base58Encoder base58EncodedValue:[photoID longLongValue]];
	NSString		*photoURL = [NSString stringWithFormat:@"http://flic.kr/p/%@", encodedID];		
	NSMutableString	*statusStr = [NSMutableString stringWithString:@"status="];
	NSURL			*twitterUrl = [NSURL URLWithString:@"https://twitter.com/statuses/update.xml"];
	NSString		*tmplt = [settings stringForKey:@"twitter_template"];		

	if (tmplt == nil) {
		tmplt = @"Uploaded \"%t\" to %u";
	}
	[statusStr appendString:tmplt];
	[statusStr replaceOccurrencesOfString:@"%u" withString:photoURL options:0 range:NSMakeRange(0,[statusStr length])];
	[statusStr replaceOccurrencesOfString:@"%t" withString:escTitle options:0 range:NSMakeRange(0,[statusStr length])];
	[escTitle release];
	
	OAConsumer			*consumer = [[OAConsumer alloc] initWithKey:kTwitterKey secret:kTwitterSecret];
	OAToken				*token = [[OAToken alloc] initWithHTTPResponseBody:tokenStr];
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:twitterUrl consumer:consumer token:token realm:nil signatureProvider:nil];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[request setTimeoutInterval:20.0];
	[request setValue:@"Flickd (http://infinite-sushi.com/software/, iPhone)" forHTTPHeaderField:@"User-Agent"];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[statusStr dataUsingEncoding:NSUTF8StringEncoding]];
	[request prepare];

	NSURLResponse	*response = nil;
	NSData			*retVal = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
	int				statusCode = [(NSHTTPURLResponse*)response statusCode];
	NSString		*errorStr = nil;	
	if ( statusCode == 401 ) {
		errorStr = @"You need to authorize Flickd to access your Twitter account.";
	} else if ( statusCode > 400 ) {
		errorStr = [NSString stringWithFormat:@"Twitter didn't accept the tweet (%d).", statusCode];
	}
	
	[request release];
	[consumer release];
	[token release];
	[self cleanupUpload:errorStr];
}

#pragma mark -
#pragma mark Web View

/**
 * Invoked by Flickr instance when a user needs to sign up for API usage.
 */
- (void)loadUrlInWebView:(NSURL*)url {
	WebViewController *wvc = [[WebViewController alloc] initWithNibName:@"WebView" bundle:[NSBundle mainBundle]];
	wvc.delegate = self;
	wvc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self.navigationController presentModalViewController:wvc animated:YES];
	[wvc loadURL:url];
	[wvc release];
}

/**
 * Invoked by the WebViewController when the user has dismissed it. 
 * Dismiss the modal view and inform the Flickr instance to retrieve the final token.
 */
- (void)webViewDone {
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[self.flickrObject performSelector:@selector(obtainToken) withObject:nil afterDelay:0.2];
}

#pragma mark -
#pragma mark Location

/**
 * Creates an EXIF field for the current geo location.
 */
- (NSMutableDictionary*)currentLocation {
    NSMutableDictionary *locDict = [[NSMutableDictionary alloc] init];
	
	if (_location != nil) {
		CLLocationDegrees exifLatitude = _location.coordinate.latitude;
		CLLocationDegrees exifLongitude = _location.coordinate.longitude;

		[locDict setObject:_location.timestamp forKey:(NSString*)kCGImagePropertyGPSTimeStamp];
		
		if (exifLatitude < 0.0) {
			exifLatitude = exifLatitude*(-1);
			[locDict setObject:@"S" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
		} else {
			[locDict setObject:@"N" forKey:(NSString*)kCGImagePropertyGPSLatitudeRef];
		}
		[locDict setObject:[NSNumber numberWithFloat:exifLatitude] forKey:(NSString*)kCGImagePropertyGPSLatitude];

		if (exifLongitude < 0.0) {
			exifLongitude=exifLongitude*(-1);
			[locDict setObject:@"W" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
		} else {
			[locDict setObject:@"E" forKey:(NSString*)kCGImagePropertyGPSLongitudeRef];
		}
		[locDict setObject:[NSNumber numberWithFloat:exifLongitude] forKey:(NSString*) kCGImagePropertyGPSLongitude];
	}
	
    return [locDict autorelease];
}

/**
 * Callback triggered by Core Location telling us the geo location has been updated.
 * Record the new location.
 */
- (void)locationUpdate:(CLLocation*)location {
	if (_location != nil)
		[_location release];
	_location = [location retain];
}

/**
 * We ignore any errors from Core Location.
 */
- (void)locationError:(NSError*)error {
}

#pragma mark -
#pragma mark Cleanup

/**
 * Free up allocated storage.
 */
- (void)dealloc {
	[assetURL release];
	[capturedPhoto release];
	[capturedVideo release];
    [mediaProperties release];
	[pickerController release];
	[locationController release];
	[imageView release];
	[_location release];
    [super dealloc];
}

@end
