/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "TagsController.h"
#import "Constants.h"

@interface TagsController (Private)
- (void)rebuildSections;
- (void)setViewMovedUp:(BOOL)movedUp;
- (UITextField*)createTextField;
@end

@implementation TagsController

@synthesize delegate, tableView;

/**
 * Initializes the controller with the given delegate. 
 * Loads tags from user defaults if previously saved and allocates storage.
 **/
- (id)initWithDelegate:(id)del {
	if ((self = [super init])) {
		// load existing tags and sort them.
		NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];
		if ([settings arrayForKey:@"tags"])
			tags = [[NSMutableArray alloc] initWithArray:[settings arrayForKey:@"tags"]];
		else
			tags = [[NSMutableArray alloc] initWithCapacity:1];
		[tags sortUsingSelector:@selector(caseInsensitiveCompare:)];
		checks = [[NSMutableDictionary alloc] initWithCapacity:1];

		// build up the indices.
		_sections = nil;
		_indices = [[NSMutableDictionary alloc] initWithCapacity:26];
		[self rebuildSections];
		
		// track the cell and tag being edited.
		_tagBeingEdited = nil;
		_cellBeingEdited = nil;
		
		// set title and delegate
		self.title = NSLocalizedString(@"Tags", @"");
		self.delegate = del;
	}
	return self;
}

/**
 * Release allocated objects.
 */
- (void)dealloc {
	self.delegate = nil;
	[tableView setDelegate:nil];
	[tableView release];
	[tags release];
	[checks release];
	[_sections release];
	[_indices release];
	[_tagBeingEdited release];
	[super dealloc];
}

/**
 * View is being loaded, set up the tableview and ask delegate for checked tags.
 */
- (void)loadView {
	tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.autoresizesSubviews = YES;
	tableView.scrollEnabled = YES;
	tableView.rowHeight = 38;
	self.view = tableView;
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	if (self.delegate && [self.delegate respondsToSelector:@selector(tagsRequested)]) {
		NSArray *array = [self.delegate performSelector:@selector(tagsRequested)];
		if (array != nil && [array count] > 0) {
			for (NSString *key in array) {
				[checks setObject:[NSNumber numberWithBool:YES] forKey:key];
			}
		}
	}
	[tableView reloadData];
}

/**
 * Support any device rotations.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

/**
 * When the view is being shown, start listening for keyboard show/hide notifications
 * so we can adjust the table view.
 */
- (void)viewWillAppear:(BOOL)animated {
    // watch the keyboard so we can adjust the user interface if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
            name:UIKeyboardWillShowNotification object:self.view.window]; 
}

/**
 * View is going away, so stop listening to keyboard notfications,
 * save the tags to the standard user defaults,
 * and pass on the checked tags to the delegate.
 */
- (void)viewWillDisappear:(BOOL)animated {
	NSUserDefaults	*settings = [NSUserDefaults standardUserDefaults];

	if (_cellBeingEdited)
		[_cellBeingEdited stopEditing];

	[settings setObject:tags forKey:@"tags"];
	if (checks != nil) {
		NSArray *sortedKeys = [[checks allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		if (self.delegate && [self.delegate respondsToSelector:@selector(tagsChangedTo:)])
			[self.delegate performSelector:@selector(tagsChangedTo:) withObject:sortedKeys];
	}
	
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
	[super setEditing:NO animated:NO];
	tableView.editing = NO;
}

/**
 * Toggle table view's editing state. If we're tracking a cell being edited,
 * inform it to stop doing what it's doing.
 */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	if (_cellBeingEdited)
		[_cellBeingEdited stopEditing];
	tableView.editing = editing;
	[tableView reloadData];
}

#pragma mark - UITableView delegates

/**
 * Rebuild the index list for the tags table. 
 */
- (void)rebuildSections {
	[_indices removeAllObjects];
	[_sections release];

	// we don't need an index if all the tags fit in the view, approximately.
	if ([tags count] < 16) {
		_sections = [[NSArray alloc] init];
		return;
	}
	
	NSUInteger idx = 0;
	for (NSString *tag in tags) {
		NSString *firstLetter = [[tag substringToIndex:1] uppercaseString];
		if (![_indices objectForKey:firstLetter]) {
			[_indices setObject:[NSNumber numberWithUnsignedInt:idx] forKey:firstLetter];
		}
		idx++;
	}

	NSUInteger maxIndices = 26;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		maxIndices = 16;
	}

	_sections = [[[_indices allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
	if ([_sections count] >= maxIndices) {
		// half it, so we don't see those ugly dots
		NSMutableArray *array = [NSMutableArray arrayWithCapacity:26];
		int skip = ([_sections count] / maxIndices)+1;
		if (skip <= 1) {
			skip = 2;
		}
		idx = 0;
		for (NSString *str in _sections) {
			if (idx % skip != 0) {
				[array addObject:str];
			}
			idx++;
		}
		
		for (NSString *str in array) {
			[_indices removeObjectForKey:str];
		}
		[_sections release];
		_sections = [[[_indices allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
	}
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tv {	
	return _sections;
}

// this is a hack. Returning row indices doesn't lead to scrolling unless it's 0. That's fine, cos we'll do it ourselves
- (NSInteger)tableView:(UITableView*)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)anIndex {
	NSNumber *idx = [_indices objectForKey:title];
	if (idx != nil) {
		[self performSelector:@selector(selectSectionIndex:) withObject:idx afterDelay:0.0];
	}
    return [self tableView:self.tableView numberOfRowsInSection:0]-1;
}

/**
 * Scroll to the first tag matching the index selected by the user.
 */
- (void)selectSectionIndex:(NSNumber*)idx {
	[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[idx unsignedIntValue] inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
}

/**
 * Return the editing style for a given row.
 */
- (UITableViewCellEditingStyle)tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	if (self.editing) {
		if (indexPath.row == 0)
			return UITableViewCellEditingStyleInsert;
		else
			return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

/**
 * Commit changes to tags listing.
 */
- (void)tableView:(UITableView*)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tags removeObjectAtIndex:indexPath.row-1];
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
		if (![tags containsObject:@""]) {
			[tags insertObject:@"" atIndex:0];
			[tv reloadData];
		}
	}
}

/**
 * Only 1 section in this table.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tv {
	return 1;
}

/**
 * The number of rows is the number of tags plus the one row the user
 * can click on to add a new tag if we are in editing mode.
 */
- (NSInteger)tableView:(UITableView*)tv numberOfRowsInSection:(NSInteger)section {
	if (self.editing)
		return [tags count] + 1;
	return [tags count];
}

/**
 * Returns the right type of cell depending on editing state of the table.
 */
- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSUInteger		row = [indexPath row];
	UITableViewCell *cell = nil;
	NSString		*tag = nil;
	
	if (self.editing && row == 0) {
		// This is the first row that triggers creation of new tags
		cell = [tv dequeueReusableCellWithIdentifier:@"newTagCell"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"newTagCell"] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			[cell.textLabel setFont:[UIFont systemFontOfSize:17]];
		}
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.text  = @"New Tag...";
	} else {
		cell = [tv dequeueReusableCellWithIdentifier:@"tagsEditTextField_ID"];
		if (cell == nil) {
			cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:@"tagsEditTextField_ID"] autorelease];
			((CellTextField*)cell).delegate = self;
			((CellTextField*)cell).hasRightMargin = YES;
			cell.accessoryType = UITableViewCellAccessoryNone;
			((CellTextField*)cell).view = [self createTextField];
			cell.textLabel.alpha = 0.0; // Text is displayed using UITextField
		}

		if (self.editing) row -= 1;
		if (row < [tags count]) {
			tag = [tags objectAtIndex:row];
			if (!self.editing && [checks objectForKey:tag])
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else
				cell.accessoryType = UITableViewCellAccessoryNone;
			[(CellTextField*)cell setEditableText:[tags objectAtIndex:row]];
		} else {
			// row for a new unsaved tag
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
	return cell;
}

/**
 * Handle toggling of tag's state if not in editing mode.
 */
- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{	
	NSUInteger row = indexPath.row;
	if (self.editing || row >= [tags count]) return;
	
	NSString *tag = [tags objectAtIndex:row];
	if ([checks objectForKey:tag])
		[checks removeObjectForKey:tag];
	else
		[checks setObject:[NSNumber numberWithBool:YES] forKey:tag];
	[tv deselectRowAtIndexPath:indexPath animated:NO];
	[tv reloadData];
}

#pragma mark -
#pragma mark Cell editing routines

/**
 * Create a textfield for the tag's table cell.
 */
- (UITextField*)createTextField {
	CGRect		frame = CGRectMake(0.0, 0.0, 100, kTextFieldHeight);
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];
   
	returnTextField.borderStyle = UITextBorderStyleNone;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:19];
    returnTextField.placeholder = @"Tap to edit tag";
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeYes;
	returnTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	returnTextField.keyboardType = UIKeyboardTypeDefault; // use the default type input method (entire keyboard)
	returnTextField.returnKeyType = UIReturnKeyDone;
	
	return [returnTextField autorelease];
}

/**
 * Callback from editable table view cell on start of editing.
 */
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell*)cell {
	if (self.editing) {
		if (_cellBeingEdited != nil) {
			[_cellBeingEdited stopEditing];
			return NO;
		}
		[_tagBeingEdited release];
		if ([cell.textLabel text])
			_tagBeingEdited = [[cell.textLabel text] copy];
		else
			_tagBeingEdited = [[NSString alloc] initWithString:@""];
		_cellBeingEdited = (CellTextField*)cell;
    } else {
		// we're actually (un)checking the tag here. 
		NSUInteger row = [tags indexOfObject:[cell.textLabel text]];
		if (row >= 0) {
			NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
			[self tableView:tableView didSelectRowAtIndexPath:path];
		}
	}
	return self.editing;
}

/**
 * Editing of table view cell has completed. Save changes and adjust scroll position.
 */
- (void)cellDidEndEditing:(EditableTableViewCell*)cell {
	if (_tagBeingEdited) {
		NSString *new_tag = [cell.textLabel text];
		
		_cellBeingEdited = nil;
		
		[tags removeObject:_tagBeingEdited];
		[_tagBeingEdited release];
		_tagBeingEdited = nil;
		if (![tags containsObject:new_tag])
			[tags addObject:[NSString stringWithString:new_tag]];
	
		[tags sortUsingSelector:@selector(caseInsensitiveCompare:)];
		[self rebuildSections];
		
		NSUInteger  row = [tags indexOfObject:new_tag];
		NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];

		[tableView reloadData];
		[tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:NO];

        // Restore the position of the main view if it was animated to make room for the keyboard.
        if  (self.view.frame.origin.y < 0) {
            [self setViewMovedUp:NO];
        }
	}
}

/**
 * When the keyboard is being shown, the row being edited must be in the visible area.
 */
- (void)keyboardWillShow:(NSNotification*)notif {
	NSIndexPath *path = [tableView indexPathForCell:_cellBeingEdited];
	CGRect		rect = [tableView rectForRowAtIndexPath:path];
	
    if (rect.origin.y >= kOFFSET_FOR_KEYBOARD) {
        [self setViewMovedUp:YES];
    }
}

/**
 * Animate the entire view up or down, to prevent the keyboard from covering the text field.
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

@end

