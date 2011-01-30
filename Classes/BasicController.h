/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "TextController.h"

/**
 * Generic controller that implements functions shared by more than one controller.
 */
@interface BasicController : UIViewController {
	MBProgressHUD	*progressHud;
	TextController	*textController;
}

@property(nonatomic,retain) MBProgressHUD *progressHud;
@property(nonatomic,retain) TextController *textController;

/**
 * Text Editor
 */
- (void)textEditorRequested:(id)sender withTitle:(NSString*)aTitle;
- (void)textChangedTo:(NSString*)txt;
- (NSString*)textRequested;

/**
 * Progress HUD display.
 */
- (void)showProgressHud:(NSString*)msg;
- (void)showProgressHud:(NSString*)msg isDeterminate:(BOOL)determinate;
- (void)closeProgressHud;
- (UIView*)viewForProgressHud;

@end
