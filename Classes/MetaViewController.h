/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>
#import "CellTextField.h"
#import "BasicController.h"

@interface MetaViewController : BasicController <UIScrollViewDelegate, UITextFieldDelegate,
												   UITableViewDelegate, UITableViewDataSource,
												   EditableTableViewCellDelegate> {
@public
	NSMutableDictionary	*metaData;
	id					delegate;
@protected
	UITableView			*tableView;
	UITextField			*textField;
@private
	id					_cell_being_edited;
}

@property(nonatomic,retain) UITableView *tableView;
@property(nonatomic,retain) NSMutableDictionary *metaData;
@property(nonatomic,assign) id delegate;

- (id)initWithDelegate:(id)del;
- (NSString*)tagsRequested;
- (void)tagsChangedTo:(NSArray*)array;
- (NSString*)textRequested;
- (void)textChangedTo:(NSString*)txt;
@end

