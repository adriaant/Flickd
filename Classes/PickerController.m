/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <objc/runtime.h>
#import "PickerController.h"

@implementation PickerController

@synthesize customBar, libraryButton, cameraButton, deviceButton;

/**
 * Initialize a UIImagePickerController with the given delegate
 * and load the overlay nib.
 */
- (id)initWithDelegate:(id)del {
	if ((self = [super init])) {
		[self setDelegate:del];
		self.allowsEditing = NO;
		self.wantsFullScreenLayout = YES;
		[[NSBundle mainBundle] loadNibNamed:@"Overlay" owner:self options:nil];
		if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
			self.deviceButton.enabled = NO;
		}
	}
	return self;
}

/**
 * In camera mode, we display our custom controls.
 */
- (void)addCustomOverlay {
	if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
		self.showsCameraControls = NO;
		if (self.cameraOverlayView != self.customBar) {
			CGRect newFrame, toolFrame, screenFrame = self.view.bounds;
			
			toolFrame = self.customBar.frame;
			self.cameraOverlayView = self.customBar;
			newFrame = self.cameraOverlayView.frame;
			newFrame.size.height = toolFrame.size.height + 9.0;
			newFrame.origin.y = screenFrame.origin.y + screenFrame.size.height - newFrame.size.height - 9.0;
			self.cameraOverlayView.frame = newFrame;
		}
		if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
			self.deviceButton.image = [UIImage imageNamed:@"user"];
		} else {
			self.deviceButton.image = [UIImage imageNamed:@"landscape"];
		}
	}
}

/**
 * View is being shown. Activate camera button and hide status bar.
 */
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self addCustomOverlay];
	cameraButton.enabled = YES;
	[[UIApplication sharedApplication] setStatusBarHidden:(self.sourceType == UIImagePickerControllerSourceTypeCamera) withAnimation:UIStatusBarAnimationFade];
}

/**
 * User clicked "Library" button. Inform delegate to make the switch.
 */
- (IBAction)libraryButtonClicked:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
		[self.delegate performSelector:@selector(imagePickerControllerDidCancel:) withObject:self];
	}
}

/**
 * User clicked camera button, so take the picture.
 */
- (IBAction)cameraButtonClicked:(id)sender {
	cameraButton.enabled = NO;
	[self takePicture];
}

/**
 * User clicked device button, so switch camera device.
 */
- (IBAction)deviceButtonClicked:(id)sender {
	if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
		self.cameraDevice = UIImagePickerControllerCameraDeviceFront;
		self.deviceButton.image = [UIImage imageNamed:@"landscape"];
	} else {
		self.cameraDevice = UIImagePickerControllerCameraDeviceRear;
		self.deviceButton.image = [UIImage imageNamed:@"user"];
	}
}

/**
 * UNUSED NOW THAT WE ACTUALLY HAVE EXIF.
 * Correct image orientation from UIImageOrientationRight (rotate on 90 degrees)
 */
- (UIImage*)correctImageOrientation:(CGImageRef)image {
	
	CGFloat width = CGImageGetWidth(image);
	CGFloat height = CGImageGetHeight(image);
	CGRect  bounds = CGRectMake(0.0f, 0.0f, width, height);
	CGFloat boundHeight = bounds.size.height;
	
	bounds.size.height = bounds.size.width;
	bounds.size.width = boundHeight;
	
	CGAffineTransform transform = CGAffineTransformMakeTranslation(height, 0.0f);
	transform = CGAffineTransformRotate(transform, M_PI / 2.0f);
	
	UIGraphicsBeginImageContext(bounds.size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(context, - 1.0f, 1.0f);
	CGContextTranslateCTM(context, -height, 0.0f);
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), image);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return imageCopy;
}

@end
