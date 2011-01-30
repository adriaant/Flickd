/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>
#import "ExchangeCredentials.h"
#import "BasicController.h"

@interface TwitterSettings : BasicController <UITextFieldDelegate, UIAlertViewDelegate, ExchangeCredentialsDelegate> {
@protected
	IBOutlet UITextField		*loginField;
	IBOutlet UITextField		*passField;
	IBOutlet UITextField		*templateField;
	IBOutlet UILabel			*authLabel;
	IBOutlet UIButton			*forgetButton;
	IBOutlet UISegmentedControl	*optionField;
@private
	ExchangeCredentials			*_credential;
}

@property(nonatomic,retain) UITextField *loginField;
@property(nonatomic,retain) UITextField *passField;
@property(nonatomic,retain) UITextField *templateField;
@property(nonatomic,retain) UILabel *authLabel;
@property(nonatomic,retain) UIButton *forgetButton;
@property(nonatomic,retain) UISegmentedControl *optionField;

- (IBAction)forget:(id)sender;

@end
