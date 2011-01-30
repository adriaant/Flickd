/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import <UIKit/UIKit.h>
#import "CellTextField.h"

/**
 * Controller for managing a list of tags associated with a given photo.
 * User can toggle multiple tags, edit the text of a tag and add/delete tags.
 */
@interface TagsController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate,
												   UITableViewDelegate, UITableViewDataSource,
												   EditableTableViewCellDelegate> {
@public
	UITableView			*tableView;
	id					delegate;

@protected
	NSMutableDictionary *checks;
	NSMutableArray		*tags;

@private
	NSString			*_tagBeingEdited;
	CellTextField		*_cellBeingEdited;
	NSMutableArray		*_sections;
	NSMutableDictionary *_indices;
}

@property(nonatomic,retain) UITableView *tableView;
@property(nonatomic,assign) id delegate;

- (id)initWithDelegate:(id)del;

@end

