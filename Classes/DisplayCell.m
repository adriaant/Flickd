/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "DisplayCell.h"
#import "Constants.h"

// cell identifier for this custom cell
NSString *kDisplayCell_ID = @"DisplayCell_ID";

@implementation DisplayCell

@synthesize textLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
	if ((self = [super initWithStyle:style reuseIdentifier:identifier]))
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		textLabel = [[UILabel alloc] initWithFrame:self.bounds];
		textLabel.font = [UIFont systemFontOfSize:17];
		textLabel.numberOfLines = 4;
		textLabel.lineBreakMode = UILineBreakModeTailTruncation;// UILineBreakModeWordWrap;
		textLabel.minimumFontSize = 12;
		textLabel.adjustsFontSizeToFitWidth = YES;
		if (self.textLabel.text) {
			textLabel.text = [NSString stringWithString:self.textLabel.text];
			self.textLabel.text = nil;
		}
		[self.contentView addSubview:textLabel];
	}
	return self;
}

- (void)layoutSubviews
{	
	[super layoutSubviews];
    CGRect contentRect = [self.contentView bounds];
	
	// In this example we will never be editing, but this illustrates the appropriate pattern
	CGRect frame = CGRectMake(contentRect.origin.x + 8, 4, contentRect.size.width - 20, 90);
	textLabel.frame = frame;
}

- (void)dealloc {
	[textLabel release];
    [super dealloc];
}

- (void)setDisplayText:(NSString*)txt {
	if (self.textLabel)
		[self.textLabel setText:txt];
}

@end
