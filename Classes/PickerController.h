/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>

@interface PickerController : UIImagePickerController {
	UIToolbar		*customBar;
	UIBarButtonItem	*libraryButton;
	UIBarButtonItem	*cameraButton;
	UIBarButtonItem *deviceButton;
}

@property(nonatomic,retain) IBOutlet UIToolbar *customBar;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *libraryButton;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *cameraButton;
@property(nonatomic,retain) IBOutlet UIBarButtonItem *deviceButton;

- (id)initWithDelegate:(id)del;
- (UIImage*)correctImageOrientation:(CGImageRef)image;
- (void)addCustomOverlay;

- (IBAction)libraryButtonClicked:(id)sender;
- (IBAction)cameraButtonClicked:(id)sender;
- (IBAction)deviceButtonClicked:(id)sender;

@end
