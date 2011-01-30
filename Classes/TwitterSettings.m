/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "TwitterSettings.h"
#import "Constants.h"

// Private interface for TextFieldController - internal only methods.
@interface TwitterSettings (Private)
- (void)setViewMovedUp:(BOOL)movedUp;
- (void)settingsDone:(id)sender;
- (void)close;
@end

@implementation TwitterSettings

@synthesize loginField, passField, authLabel, forgetButton;
@synthesize templateField, optionField;

/**
 * View was loaded, configure the UI elements.
 */
- (void)viewDidLoad {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	[self.view setFrame:[[UIScreen mainScreen] applicationFrame]];
	[self.view setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];

	if ([settings stringForKey:@"twitter_token"] != nil) {
		authLabel.text = [NSString stringWithFormat:@"Authorized by Twitter for account named \"%@\".", [settings stringForKey:@"twitter_username"]];
		authLabel.superview.hidden = NO;
		passField.superview.hidden = YES;
	} else {
		authLabel.superview.hidden = YES;
		passField.superview.hidden = NO;
		if ([settings stringForKey:@"twitter_username"] != nil)
			[loginField setText:[settings stringForKey:@"twitter_username"]];
		[loginField setDelegate:self];
		[passField setDelegate:self];
	}

	if ([settings stringForKey:@"twitter_template"] != nil)
		[templateField setText:[settings stringForKey:@"twitter_template"]];
	if ([settings stringForKey:@"twitter_option"] != nil) {
		NSString *str = [settings stringForKey:@"twitter_option"];
		if ([str isEqualToString:@"YES"])
			[optionField setSelectedSegmentIndex:0];
		else
			[optionField setSelectedSegmentIndex:1];
	}	
	[templateField setDelegate:self];
	
	UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(settingsDone:)];
	self.navigationItem.leftBarButtonItem = doneButtonItem;
	[doneButtonItem release];
}

/**
 * User dismissed the view and authorize with Twitter if we have info
 * and if the user wants to send notifications to Twitter.
 */
- (void)settingsDone:(id)sender {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

	if ([optionField selectedSegmentIndex] == 0)
		[settings setObject:@"YES" forKey:@"twitter_option"];
	else
		[settings setObject:@"NO" forKey:@"twitter_option"];
	[settings synchronize];

	if ([settings stringForKey:@"twitter_token"] != nil || [optionField selectedSegmentIndex] != 0 || [passField.text length] == 0 || [loginField.text length] == 0) {
		[self close];
	} else {
		// retrieve access token
		self.navigationItem.leftBarButtonItem.enabled = NO;
		_credential = [[ExchangeCredentials alloc] initWithDelegate:self 
			username:[loginField text] password:passField.text];
		[self showProgressHud:[NSString stringWithFormat:NSLocalizedString(@"Authenticating \"%@\"...", @"Progress message for verifying user's credentials"), loginField.text]];
		[_credential requestToken];	
	}
}

/**
 * User requested deletion of authentication data.
 */
- (IBAction)forget:(id)sender {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	[settings removeObjectForKey:@"twitter_token"];
	[settings removeObjectForKey:@"twitter_user"];
	[settings synchronize];

 	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.1];
	loginField.superview.hidden = NO;
	authLabel.superview.hidden = YES;
	[UIView commitAnimations];
	[loginField setDelegate:self];
	[passField setDelegate:self];
}

#pragma mark -
#pragma mark OAuth

/**
 * Called when Twitter authorization failed.
 */
- (void)credentialFailed:(ExchangeCredentials*)credential {
	[self closeProgressHud];

	NSInteger code = [credential.error code];
	NSString  *h = NSLocalizedString(@"Failure", @"Failure alert header"), *msg = nil;
	
	if (code == NSURLErrorNetworkConnectionLost || code == NSURLErrorNotConnectedToInternet) {
		msg = NSLocalizedString(@"No network connection.", @"Network down.");
	} else if (code == NSURLErrorTimedOut) {
		msg = NSLocalizedString(@"Connection timed out, try again in a minute.", @"Connection fail");
	} else if (code >= 500) {
		msg = NSLocalizedString(@"Twitter is overloaded, try again in a minute.", @"API fail");
	} else {
		msg = NSLocalizedString(@"Twitter rejected the authentication. Please check your username and password.", @"Failed to authenticate user");
		h = NSLocalizedString(@"Access Denied", @"Credentials failed alert header");
	}

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:h message:msg delegate:self
		cancelButtonTitle:NSLocalizedString(@"OK", @"OK button") otherButtonTitles:nil];
	[alert show];
	[alert release];

	_credential.delegate = nil;
	[_credential release]; _credential = nil;
	self.navigationItem.leftBarButtonItem.enabled = YES;
}

/**
 * Called when Twitter authorization succeeded.
 */
- (void)credentialSucceeded:(ExchangeCredentials*)credential {

	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	[settings setObject:credential.token forKey:@"twitter_token"];
	[settings setObject:loginField.text forKey:@"twitter_username"];
	if ([optionField selectedSegmentIndex] == 0)
		[settings setObject:@"YES" forKey:@"twitter_option"];
	else
		[settings setObject:@"NO" forKey:@"twitter_option"];
	[settings synchronize];
	
	[self.progressHud setLabelText:NSLocalizedString(@"Authentication approved.", @"Authentication success")];
	self.progressHud.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark.png"]] autorelease];
    self.progressHud.mode = MBProgressHUDModeCustomView;
	[self performSelector:@selector(close) withObject:nil afterDelay:1];
}

/**
 * User dismissed alert view. Make login field the active element.
 */
- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	self.passField.text = @"";
	[self.loginField becomeFirstResponder];
}

/**
 * Close the current view, effectively returning control to MetaViewController.
 */
- (void)close {	
	if (progressHud) {
		[self closeProgressHud];
	}
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

/**
 * This helps dismiss the keyboard then the "done" button is clicked.
 */
- (BOOL)textFieldShouldReturn:(UITextField*)textField {
	[textField resignFirstResponder];
	if (textField == templateField && self.view.frame.origin.y < 0) {
        [self setViewMovedUp:NO];
	}
	return YES;
}

/**
 * Animate the entire view up or down, to prevent the keyboard from covering the edited field.
 */
- (void)setViewMovedUp:(BOOL)movedUp {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    // Make changes to the view's frame inside the animation block. They will be animated instead
    // of taking place immediately.
    CGRect rect = self.view.frame;
    if (movedUp) {
        // If moving up, not only decrease the origin but increase the height so the view 
        // covers the entire screen behind the keyboard.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    } else {
        // If moving down, not only increase the origin but decrease the height.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

/**
 * The keyboard will be shown. If the user is editing the template, adjust the display so that the
 * template field will not be covered by the keyboard.
 */
- (void)keyboardWillShow:(NSNotification*)notif {
    if ([templateField isFirstResponder] && self.view.frame.origin.y >= 0) {
        [self setViewMovedUp:YES];
    } else if (![templateField isFirstResponder] && self.view.frame.origin.y < 0) {
        [self setViewMovedUp:NO];
    }
}

/**
 * When the view is being shown, start listening for keyboard show/hide notifications
 * so we can adjust the view.
 */
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
            name:UIKeyboardWillShowNotification object:self.view.window]; 
}

/**
 * View is going away, so stop listening to keyboard notfications.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

/**
 * Release allocated objects.
 */
- (void)dealloc {
	if (progressHud) {
		[self closeProgressHud];
	}
	if (_credential) {
		_credential.delegate = nil;
		[_credential release];
	}
    [super dealloc];
}

@end
