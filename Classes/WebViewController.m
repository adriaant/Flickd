/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "WebViewController.h"

@implementation WebViewController

@synthesize delegate, webButton, webLabel, webSpinner, webView;

/**
 * Initializes a web view controller using a Nib file and initially hides some UI elements.
 */
- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		webSpinner.hidden = YES;
		webLabel.hidden = YES;
		webButton.hidden = YES;
	}
	return self;
}

/**
 * Set the resizing mask, frame, background color and
 * make sure we get the webview's delegate calls.
 */
- (void)viewDidLoad {
	self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	[self.view setFrame:[[UIScreen mainScreen] bounds]];
	[self.view setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
	[webView setDelegate:self];
}

/**
 * Load the given url in the webview.
 */
- (void)loadURL:(NSURL*)url {
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	webSpinner.hidden = NO;
	webLabel.hidden = NO;
	webButton.hidden = YES;
	[webView loadRequest:requestObj];
}

/**
 * Support any device rotations.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

/**
 * Release allocated storage.
 */
- (void)dealloc {
	[webView setDelegate:nil];
	[webView release];
	[super dealloc];
}

#pragma mark -
#pragma mark Web View Delegate Calls

/**
 * Webview is asking permission to load a request. If it looks like we're nearing the end of authentication,
 * then reveal the dismission button.
 */
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSURL	 *url = [request URL];
	NSString *urlStr = [url absoluteString];
	if ([urlStr isEqualToString:@"http://m.flickr.com/#/services/auth/"]) {
		webButton.hidden = NO;
	}
	return YES;
}

/**
 * Show progress animation during loads.
 */
- (void)webViewDidStartLoad:(UIWebView*)webView {
	webSpinner.hidden = NO;
	[webSpinner startAnimating];
	webLabel.hidden = NO;
	webButton.hidden = YES;
}

/**
 * Stop progress animation.
 */
- (void)webViewDidFinishLoad:(UIWebView*)wv {
	[webSpinner stopAnimating];
	webSpinner.hidden = YES;
	webLabel.hidden = YES;
}

/**
 * User finished authentication or cancelled it. 
 * Inform delegate that we're done.
 */
- (IBAction)dismissWebView:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(webViewDone)]) {
		[self.delegate performSelector:@selector(webViewDone)];
	}
}

@end
