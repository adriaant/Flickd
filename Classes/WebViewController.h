/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController <UIWebViewDelegate> {
@public
	id								 delegate;
@protected
	IBOutlet UIWebView				 *webView;
	IBOutlet UILabel				 *webLabel;
	IBOutlet UIButton				 *webButton;
	IBOutlet UIActivityIndicatorView *webSpinner;
}

@property(nonatomic,assign) id delegate;
@property(nonatomic,retain) UIWebView *webView;
@property(nonatomic,retain) UILabel *webLabel;
@property(nonatomic,retain) UIButton *webButton;
@property(nonatomic,retain) UIActivityIndicatorView *webSpinner;

- (void)loadURL:(NSURL*)url;
- (IBAction)dismissWebView:(id)sender;

@end
