/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "TextController.h"

@implementation TextController

@synthesize delegate, textView;

- (id)initWithDelegate:(id)del {
	if ((self = [super init])) {
		self.delegate = del;
		self.title = NSLocalizedString(@"Description", @"");
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	[super dealloc];
}

- (void)loadView {
	textView = [[UITextView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];	
	textView.delegate = self;
	textView.autoresizesSubviews = YES;
	textView.scrollEnabled = YES;
	[textView setFont:[UIFont systemFontOfSize:17]];
	self.view = textView;
	[textView becomeFirstResponder];
	[textView release];
	if (self.delegate && [self.delegate respondsToSelector:@selector(textRequested)])
		[textView setText:[self.delegate performSelector:@selector(textRequested)]];
}

- (void)textViewDidEndEditing:(UITextView*)txtView {
	if (self.delegate && [self.delegate respondsToSelector:@selector(textChangedTo:)])
		[self.delegate performSelector:@selector(textChangedTo:) withObject:[txtView text]];
}

@end

