/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>

@interface TextController : UIViewController <UITextViewDelegate> {
	UITextView	*textView;
	id			delegate;
}

@property(nonatomic,assign) id delegate;
@property(nonatomic,retain) UITextView *textView;

- (id)initWithDelegate:(id)del;

@end

