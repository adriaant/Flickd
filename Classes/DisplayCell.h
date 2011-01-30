/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kDisplayCell_ID;

@interface DisplayCell : UITableViewCell {
	UILabel	*textLabel;
}

@property(nonatomic,retain) UILabel *textLabel;

- (void)setDisplayText:(NSString *)txt;
@end
