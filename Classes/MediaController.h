/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>
#import "BasicController.h"
#import "PickerController.h"
#import "LocationController.h"
#import "Flickr.h"

@interface MediaController : BasicController <UINavigationControllerDelegate, 
                                              UIImagePickerControllerDelegate, 
											  LocationControllerDelegate, 
											  UIAlertViewDelegate,
											  FlickrDelegate> {
@protected
	UIImageView			*imageView;
	NSURL				*assetURL;
	UIImage				*capturedPhoto;
	NSURL				*capturedVideo;
	NSMutableDictionary *mediaProperties;
	PickerController	*pickerController;
	LocationController	*locationController;
	Flickr				*flickrObject;
@private
	CLLocation			*_location;
}

@property(nonatomic,retain) IBOutlet UIImageView *imageView;
@property(nonatomic,retain) NSURL *assetURL;
@property(nonatomic,retain) UIImage *capturedPhoto;
@property(nonatomic,retain) NSURL *capturedVideo;
@property(nonatomic,retain) NSMutableDictionary *mediaProperties;
@property(nonatomic,retain) PickerController *pickerController;
@property(nonatomic,retain) LocationController *locationController;
@property(nonatomic,retain) Flickr *flickrObject;

- (void)showImagePickerAfterDelay:(NSNumber*)type;
- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType animated:(BOOL)animated;
- (void)locationUpdate:(CLLocation*)location; 
- (void)locationError:(NSError*)error;
- (void)uploadRequested:(NSMutableDictionary*)metadata;
- (void)uploadCancelled;
- (void)uploadApproved;

// Flickr delegate calls
- (void)uploadFinished:(NSString*)photoId;
- (void)uploadFailed:(NSString*)err;
- (void)loadUrlInWebView:(NSURL*)url;
- (void)setProgress:(float)val;

@end
