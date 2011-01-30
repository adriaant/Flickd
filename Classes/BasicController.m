/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "BasicController.h"

@implementation BasicController

@synthesize progressHud, textController;

#pragma mark -
#pragma mark Text Editor

- (void)textEditorRequested:(id)sender withTitle:(NSString*)aTitle {
	if (!textController)
		textController = [[TextController alloc] initWithDelegate:sender];
	textController.title = aTitle;
	[self.navigationController pushViewController:textController animated:YES];
}

- (NSString*)textRequested {
	return @"";
}

- (void)textChangedTo:(NSString*)txt {
}

#pragma mark -
#pragma mark Progress Hud

- (void)showProgressHud:(NSString*)msg {
	[self showProgressHud:msg isDeterminate:NO];
}

- (void)showProgressHud:(NSString*)msg isDeterminate:(BOOL)determinate {
	if (self.progressHud == nil) {
		MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
		self.progressHud = HUD;
		
		// Set determinate mode
		if (determinate) {
			progressHud.mode = MBProgressHUDModeDeterminate;
		}

		progressHud.labelText = msg;
		[[self viewForProgressHud] addSubview:progressHud];
		[progressHud show:YES];
	}
}

- (UIView*)viewForProgressHud {
	return self.view;
}

- (void)closeProgressHud {
	if (self.progressHud != nil) {
		[self.progressHud hide:YES];
		[self.progressHud removeFromSuperview];
		self.progressHud = nil;
	}
}

#pragma mark -
#pragma mark CleanUp

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
	[self closeProgressHud];
	self.textController = nil;
	self.view = nil;
    [super dealloc];
}

@end
