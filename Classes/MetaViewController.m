/* 
 * Created by Adriaan Tijsseling
 * http://infinite-sushi.com
 * This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. 
 * To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ or 
 * send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
 */
 
#import "MetaViewController.h"
#import "Constants.h"
#import "CellTextField.h"
#import "DisplayCell.h"
#import "TwitterSettings.h"
#import "TagsController.h"

// initial width, but the table cell will dictact the actual width
#define kTextFieldWidth							100.0
// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration		0.30

@interface MetaViewController (Private)
- (void)createTextField;
- (void)upload:(id)sender;
- (void)cancel:(id)sender;
- (void)configureTwitter:(id)sender;
- (void)editTags:(id)sender;
@end

@implementation MetaViewController

@synthesize tableView, metaData, delegate;

/**
 * Sections in our table view.
 */
enum TableSections {
	kTextSection = 0,
	kTagsSection,
	kPrivacySection,
	kNotifySection
};

/**
 * Initialize with the given delegate. 
 * Allocate the dictionary to hold the values for title, description and tags.
 */
- (id)initWithDelegate:(id)del {
	if ((self = [super init])) {
		self.delegate = del;
		self.metaData = [NSMutableDictionary dictionaryWithCapacity:5];
		self.title = NSLocalizedString(@"Info", @"");
		_cell_being_edited = nil;
	}
	return self;
}

/**
 * Create and configure the table view and make a recycle editable text field.
 */
- (void)loadView {
	self.tableView = [[[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped] autorelease];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.autoresizesSubviews = YES;
	tableView.scrollEnabled = YES;
	tableView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
	self.view = tableView;
	
	// create our text field to be recycled when UITableViewCells are created
	[self createTextField];	
}

/**
 * Support any device rotations.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

/**
 * Create an editable text field for the tag table cell.
 */
- (void)createTextField {
	CGRect		frame = CGRectMake(0.0, 0.0, kTextFieldWidth, kTextFieldHeight);
	textField = [[UITextField alloc] initWithFrame:frame];
   
	textField.borderStyle = UITextBorderStyleNone;
    textField.textColor = [UIColor blackColor];
	textField.font = [UIFont systemFontOfSize:17];
    textField.placeholder = @"Title";
    textField.backgroundColor = [UIColor whiteColor];
	textField.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
	textField.keyboardType = UIKeyboardTypeDefault; // use the default type input method (entire keyboard)
	textField.returnKeyType = UIReturnKeyDone;
	textField.clearButtonMode = UITextFieldViewModeWhileEditing; // has a clear 'x' button to the right
}

/**
 * Dispose of allocated storage.
 */
- (void)dealloc {
	[tableView setDelegate:nil];
	[tableView release];
	[metaData release];
	[textField release];
	[super dealloc];
}

#pragma mark -
#pragma mark - UITableView delegates

- (UITableViewCellEditingStyle)tableView:(UITableView*)tableView editingStyleForRowAtIndexPath:(NSIndexPath*)indexPath {
	return UITableViewCellEditingStyleNone;
}

/**
 * Four sections in this table view: Title+Description, Tags, Privacy, Notifications
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
	return 4;
}

/**
 * Return the appropriate header for the given section.
 */
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *title = nil;
	switch (section) {
		case kTagsSection:
		{
			title = @"Tags";
			break;
		}
		case kPrivacySection:
		{
			title = @"Privacy";
			break;
		}
		case kNotifySection:
		{
			title = @"Twitter";
			break;
		}
	}
	return title;
}

/**
 * Return the number of rows in the given section. Only the top section has 2 rows,
 * everything else has only 1 row.
 */
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kTextSection) {
		return 2;
	}
	return 1;
}

/**
 * Title and description rows have different row heights. 
 */
- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	CGFloat	  result;
	
	switch (section) {
		case kTextSection:
		{
			if (row == 1) {
				result = 96;
			} else {
				result = 34;
			}
			break;
		}
		default:
		{
			result = 43;
			break;
		}
	}
	return result;
}

/**
 * If user touches anywhere else but the text field being edited,
 * cancel the editing so the keyboard goes away.
 */
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  for (UIView* view in self.view.subviews) {
    if ([view isKindOfClass:[UITextField class]])
      [view resignFirstResponder];
  }
  if (_cell_being_edited != nil)
	[((CellTextField*)_cell_being_edited).view resignFirstResponder];
}

/**
 * Description, tags and notification rows need to be tapped by the user 
 * to show the appropriate view controller.
 */
- (void)tableView:(UITableView*)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath {
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];

	if (_cell_being_edited != nil)
		[((CellTextField*)_cell_being_edited).view resignFirstResponder];

	switch (section) {
		case kTextSection:
		{
			if (row == 1) {
				[self textEditorRequested:self withTitle:@"Description"];
			}
			break;
		}
		case kTagsSection:
		{
			[self editTags:tv];
			break;
		}
		case kNotifySection:
		{
			[self configureTwitter:tv];
			break;
		}
	}
}

/**
 * Returns the right type of cell depending on section and row.
 */
- (UITableViewCell*)tableView:(UITableView*)tv cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	NSInteger section = [indexPath section];
	NSInteger row = [indexPath row];
	
	UITableViewCell *cell = nil;
	
	switch (section) {
		case kTextSection:
		{
			if (row == 0) {
				cell = [tv dequeueReusableCellWithIdentifier:kCellTextField_ID];
				if (cell == nil) {
					cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
					cell.textLabel.alpha = 0.0; // text will be displayed in a UITextField added to the cell's contentview.
					((CellTextField*)cell).delegate = self;
				}
				((CellTextField*)cell).view = textField;
				if ([metaData objectForKey:@"Title"] != nil)
					[(CellTextField*)cell setEditableText:[metaData objectForKey:@"Title"]];
			} else if (row == 1) {
				cell = [tv dequeueReusableCellWithIdentifier:kDisplayCell_ID];
				if (cell == nil) {
					cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
					
					[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
					[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
				}
				
				[cell.textLabel setFont:[UIFont systemFontOfSize:17]];
				[cell.textLabel setLineBreakMode:UILineBreakModeWordWrap];
				if ([metaData objectForKey:@"Description"] != nil)
					[(DisplayCell*)cell setDisplayText:[metaData objectForKey:@"Description"]];
			}
			break;
		}
		case kTagsSection:
		{
			cell = [tv dequeueReusableCellWithIdentifier:@"tableTagsCell"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"tableTagsCell"] autorelease];
				[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			}
			
			[cell.textLabel setFont:[UIFont systemFontOfSize:17]];
			[cell.textLabel setLineBreakMode:UILineBreakModeHeadTruncation];
			if ([metaData objectForKey:@"Tags"] != nil) {
				NSString *tagsStr = [[metaData objectForKey:@"Tags"] componentsJoinedByString:@", "];
				[cell.textLabel setText:tagsStr];
			}
			break;
		}
		case kPrivacySection:
		{
			cell = [tv dequeueReusableCellWithIdentifier:@"tablePrivacyCell"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"tablePrivacyCell"] autorelease];
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			}
			
			[cell.textLabel setFont:[UIFont systemFontOfSize:17]];
			[cell.textLabel setLineBreakMode:UILineBreakModeHeadTruncation];
			NSInteger privacyMode = 4; // public
			if ([metaData objectForKey:@"Privacy"] != nil) {
				privacyMode = [[metaData objectForKey:@"Privacy"] intValue];
			} else {
				NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
				if ([settings objectForKey:@"privacy"] != nil) {
					privacyMode = [settings integerForKey:@"privacy"];
				}
				[metaData setObject:[NSNumber numberWithInt:privacyMode] forKey:@"Privacy"];
			}
			switch (privacyMode) {
				case 4:
					[cell.textLabel setText:@"Public"];
					[cell setTag:4];
					break;
				case 3:
					[cell.textLabel setText:@"Friends & Family"];
					[cell setTag:3];
					break;
				case 2:
					[cell.textLabel setText:@"Friends"];
					[cell setTag:2];
					break;
				case 1:
					[cell.textLabel setText:@"Family"];
					[cell setTag:1];
					break;
				case 0:
					[cell.textLabel setText:@"Private"];
					[cell setTag:0];
					break;
			}
			break;
		}
		case kNotifySection:
		{
			cell = [tv dequeueReusableCellWithIdentifier:@"tableTwitterCell"];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"tableTwitterCell"] autorelease];
				[cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
				[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			}
			[cell.textLabel setFont:[UIFont systemFontOfSize:17]];
			[cell.textLabel setLineBreakMode:UILineBreakModeHeadTruncation];
			[cell.textLabel setText:@"Configure"];
			break;
		}
	}
	
	return cell;
}

/**
 * Handle toggling of privacy setting.
 */
- (void)tableView:(UITableView*)tv didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
	if ([indexPath section] == kPrivacySection && [indexPath row] == 0) {
		UITableViewCell *cell = [tv cellForRowAtIndexPath:indexPath];
		NSInteger		privacyMode = 3; // default is public, so select next mode
		
		if ([metaData objectForKey:@"Privacy"] != nil) {
			privacyMode = [[metaData objectForKey:@"Privacy"] intValue];
			if (privacyMode == 0)
				privacyMode = 4;
			else
				privacyMode = privacyMode - 1;
		}
		[metaData setObject:[NSNumber numberWithInt:privacyMode] forKey:@"Privacy"];
		
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		[settings setInteger:privacyMode forKey:@"privacy"];
		[settings synchronize];
		
		if (cell != nil) {
			switch (privacyMode) {
				case 4:
					[cell.textLabel setText:@"Public"];
					[cell setTag:4];
					break;
				case 3:
					[cell.textLabel setText:@"Friends & Family"];
					[cell setTag:3];
					break;
				case 2:
					[cell.textLabel setText:@"Friends"];
					[cell setTag:2];
					break;
				case 1:
					[cell.textLabel setText:@"Family"];
					[cell setTag:1];
					break;
				case 0:
					[cell.textLabel setText:@"Private"];
					[cell setTag:0];
					break;
			}
		}
	}
}

/**
 * Display view controller for configuring Twitter settings.
 */
- (void)configureTwitter:(id)sender {
	TwitterSettings *tc = [[TwitterSettings alloc] initWithNibName:@"Twitter" bundle:[NSBundle mainBundle]];
	[self.navigationController pushViewController:(UIViewController*)tc animated:YES];
	[tc release];
}

#pragma mark -
#pragma mark <Text/TagsController> Methods and editing management

/**
 * Display view controller for editing tags.
 */
- (void)editTags:(id)sender {
	TagsController *tc = [[TagsController alloc] initWithDelegate:self];
	[self.navigationController pushViewController:tc animated:YES];
	[tc release];
}

/**
 * Called by TagsController when it needs the tags for the current photo.
 */
- (NSString*)tagsRequested {
	return [metaData objectForKey:@"Tags"];
}

/**
 * The user has finished editing tags so we need to update the appropriate row.
 */
- (void)tagsChangedTo:(NSArray*)array {
	if (array != nil)
		[metaData setObject:[NSArray arrayWithArray:array] forKey:@"Tags"];
	else
		[metaData setObject:[NSArray array] forKey:@"Tags"];
	[tableView reloadData];
}

/**
 * Called by TextController to return the text that needs to be edited.
 */
- (NSString*)textRequested {
	return [metaData objectForKey:@"Description"];
}

/**
 * The user has finished editing text so we need to update the appropriate row.
 */
- (void)textChangedTo:(NSString*)txt {
	if (txt != nil)
		[metaData setObject:[NSString stringWithString:txt] forKey:@"Description"];
	else
		[metaData setObject:@"" forKey:@"Description"];
	[tableView reloadData];
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing

/**
 * Title row's editable cell delegate call.
 */
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell*)cell {
	_cell_being_edited = cell;
    return YES;
}

/**
 * Title row's editable cell delegate call.
 */
- (void)cellDidEndEditing:(EditableTableViewCell*)cell {
	_cell_being_edited = nil;
	if ([cell.textLabel text] != nil)
		[metaData setObject:[NSString stringWithString:[cell.textLabel text]] forKey:@"Title"];
}

#pragma mark -
#pragma mark - UIViewController delegate methods

/**
 * View will be shown. Set the right bar button to "Upload"
 * and hide the back button.
 */
- (void)viewWillAppear:(BOOL)animated {
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStylePlain target:self action:@selector(upload:)] autorelease];
	self.navigationItem.hidesBackButton = YES;
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
	[self.navigationController setNavigationBarHidden:NO animated:YES];
}

/**
 * View is going away. Make sure to stop the editor so
 * that changes to the title are recorded.
 */
- (void)viewWillDisappear:(BOOL)animated {
  if (_cell_being_edited != nil)
	[((CellTextField*)_cell_being_edited).view resignFirstResponder];
}

/**
 * User is done editing the meta data. Tell delegate to proceed with upload.
 */
- (void)upload:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(uploadRequested:)])
		[self.delegate performSelector:@selector(uploadRequested:) withObject:self.metaData];
}

/**
 * User doesn't want to upload
 */
- (void)cancel:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(uploadCancelled)])
		[self.delegate performSelector:@selector(uploadCancelled)];
}

@end
