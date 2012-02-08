//
//  ESDebugConsole+iOS_GUI.m
//
//  Copyright Doug Russell 2012. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>
#import "ESDebugConsole+iOS_GUI.h"
#import "ARCLogic.h"
#import "ESConsoleEntry.h"

@interface ESDebugConsole ()
@end

#define ISPAD [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#define ISPHONE [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone

@interface ESDebugAppListTableViewController : UITableViewController
@property (nonatomic, retain) NSDictionary *allApplicationLogs;
@property (nonatomic, retain) NSArray *allApps;
@end

@interface ESDebugTableViewController : UITableViewController
@property (nonatomic, retain) NSArray *applicationLogs;
@property (nonatomic, retain) UISegmentedControl *segmentedControl;
@end

@interface ESDebugTableViewCell : UITableViewCell
@property (nonatomic, retain) UILabel *applicationIdentifierLabel;
@property (nonatomic, retain) UILabel *messageLabel;
@property (nonatomic, retain) UILabel *dateLabel;
@end

@interface ESDebugDetailViewController : UIViewController
@property (nonatomic, retain) UITextView *textView;
@end

@implementation ESDebugConsole (iOS_GUI)

#pragma mark - 

- (void)lowMemoryWarning:(NSNotification *)notification
{
	[self.popoverController dismissPopoverAnimated:NO];
	self.popoverController = nil;
	if ([self.navigationController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
		[self.navigationController dismissViewControllerAnimated:YES completion:nil];
	else
		[self.navigationController dismissModalViewControllerAnimated:YES];
	self.navigationController = nil;
}

#pragma mark - 

- (void)gestureRecognized:(UIGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state != UIGestureRecognizerStateEnded)
		return;
	
	if (ISPAD)
	{
		if ([self.popoverController isPopoverVisible])
			return;
		[self.popoverController presentPopoverFromRect:CGRectMake(0, 0, 10, 10) 
												inView:gestureRecognizer.view 
							  permittedArrowDirections:UIPopoverArrowDirectionAny 
											  animated:YES];
	}
	else if (ISPHONE)
	{
		if (self.window.rootViewController.modalViewController != nil)
			return;
		[self.window.rootViewController presentModalViewController:self.navigationController animated:YES];
	}
}

#pragma mark - Accessors

- (UIWindow *)window
{
	return _window;
}

- (void)setWindow:(UIWindow *)window
{
	if (_window != window)
	{
		NO_ARC(
			   [window retain];
			   [_window release];
			   )
		_window = window;
	}
}

- (UIPopoverController *)popoverController
{
	if (_popoverController == nil)
	{
		if (!(ISPAD))
			return nil;
		_popoverController = [[UIPopoverController alloc] initWithContentViewController:self.navigationController];
	}
	return _popoverController;
}

- (void)setPopoverController:(UIPopoverController *)popoverController
{
	if (_popoverController != popoverController)
	{
		NO_ARC(
			   [popoverController retain];
			   [_popoverController release];
			   )
		_popoverController = popoverController;
	}
}

- (UINavigationController *)navigationController
{
	if (_navigationController == nil)
	{
		ESDebugAppListTableViewController *tvc = [ESDebugAppListTableViewController new];
		if (!CGSizeEqualToSize(self.consoleSizeInPopover, CGSizeZero))
			tvc.contentSizeForViewInPopover = self.consoleSizeInPopover;
		_navigationController = [[UINavigationController alloc] initWithRootViewController:tvc];
		NO_ARC([tvc release];)
	}
	return _navigationController;
}

- (void)setNavigationController:(UINavigationController *)navigationController
{
	if (_navigationController != navigationController)
	{
		NO_ARC(
			   [navigationController retain];
			   [_navigationController release];
			   )
		_navigationController = navigationController;
	}
}

- (UIGestureRecognizer *)gestureRecognizer
{
	return _gestureRecognizer;
}

- (void)setGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
{
	if (_gestureRecognizer != gestureRecognizer)
	{
		if (_gestureRecognizer != nil)
			[((UIGestureRecognizer *)_gestureRecognizer).view removeGestureRecognizer:_gestureRecognizer];
		NO_ARC(
			   [_gestureRecognizer release];
			   [gestureRecognizer retain];
			   )
		_gestureRecognizer = gestureRecognizer;
	}
}

- (CGSize)consoleSizeInPopover
{
	return _consoleSizeInPopover;
}

- (void)setConsoleSizeInPopover:(CGSize)consoleSizeInPopover
{
	if (!CGSizeEqualToSize(consoleSizeInPopover, _consoleSizeInPopover))
	{
		_consoleSizeInPopover = consoleSizeInPopover;
	}
}

@end

@implementation ESDebugConsole (iOS_GUI_Private)

- (void)iOSInit
{
	UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window)
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	if (window == nil)
	{
		[NSException raise:@"Nil Window Exception" format:@"Activated ESDebugConsole without a window to attach to"];
		return;
	}
	if (window.rootViewController == nil && ISPHONE)
	{
		[NSException raise:@"Nil Root View Controller Exception" format:@"Activated ESDebugConsole without a root view controller to attach to"];
		return;
	}
	self.window = window;
    self.consoleSizeInPopover = CGSizeZero;
	UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognized:)];
	rotationGesture.cancelsTouchesInView = NO;
	self.gestureRecognizer = rotationGesture;
	[window addGestureRecognizer:rotationGesture];
	NO_ARC([rotationGesture release];)
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lowMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)iOSDealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	NO_ARC(
		   [_window release];
		   [_popoverController release];
		   [_navigationController release];
		   [_gestureRecognizer release];
		   )
}

@end

@implementation ESDebugAppListTableViewController
@synthesize allApplicationLogs=_allApplicationLogs;
@synthesize allApps=_allApps;

#pragma mark - 

- (void)dealloc
{
	NO_ARC(
		   [_allApplicationLogs release];
		   [_allApps release];
		   [super dealloc];
		   )
}

#pragma mark - 

- (void)done:(id)sender
{
	if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
		[self dismissViewControllerAnimated:YES completion:nil];
	else
		[self dismissModalViewControllerAnimated:YES];
}

- (void)refresh:(id)sender
{
	UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[activity startAnimating];
	UIBarButtonItem *activityButton = [[UIBarButtonItem alloc] initWithCustomView:activity];
	NO_ARC([activity release];)
	self.navigationItem.leftBarButtonItem = activityButton;
	NO_ARC([activityButton release];)
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
		NSDictionary *logs = [ESDebugConsole getConsole];
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			self.allApplicationLogs = logs;
			NSMutableArray *allApps = [[self.allApplicationLogs allKeys] mutableCopy];
			[allApps removeObject:kESDebugConsoleAllLogsKey];
			self.allApps = allApps;
			NO_ARC([allApps release];)
			[self.tableView reloadData];
			UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
			self.navigationItem.leftBarButtonItem = refreshButton;
			NO_ARC([refreshButton release];)
		});
	});
}

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"App List";
	
	if (ISPHONE)
	{
		UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
		self.navigationItem.rightBarButtonItem = doneButton;
		NO_ARC([doneButton release];)
	}
	
	if ([[ESDebugConsole sharedDebugConsole] respondsToSelector:@selector(sendConsoleAsEmail)])
	{
		UIBarButtonItem *email = [[UIBarButtonItem alloc] initWithTitle:@"Email Logs" style:UIBarButtonItemStyleBordered target:self action:@selector(email:)];
		self.toolbarItems = [NSArray arrayWithObjects:
							 email,
							 nil];
		NO_ARC([email release];)
		[self.navigationController setToolbarHidden:NO animated:NO];
		[self.navigationController setToolbarItems:self.toolbarItems];
	}
	
	[self refresh:nil];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.allApplicationLogs = nil;
	self.allApps = nil;
}

#pragma mark - 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.allApps)
		return self.allApps.count + 2;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
		NO_ARC([cell autorelease];)
	}
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = @"All";
			break;
		case 1:
			cell.textLabel.text = @"Current";
			break;
		default:
			cell.textLabel.text = [self.allApps objectAtIndex:indexPath.row-2];
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ESDebugTableViewController *tvc = [ESDebugTableViewController new];
    tvc.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	switch (indexPath.row) {
		case 0:
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:kESDebugConsoleAllLogsKey];
			break;
		case 1:
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:[[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleIdentifierKey]];
			break;
		default:
			tvc.applicationLogs = [self.allApplicationLogs objectForKey:[self.allApps objectAtIndex:indexPath.row-2]];
			break;
	}
	[self.navigationController pushViewController:tvc animated:YES];
	NO_ARC([tvc release];)
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

#pragma mark - Email

- (void)email:(id)sender
{
	[[ESDebugConsole sharedDebugConsole] performSelector:@selector(setMessage:) withObject:[NSString stringWithFormat:@"Console Logs: \n\n%@", [[ESDebugConsole getConsole] objectForKey:kESDebugConsoleAllLogsKey]]];
	[[ESDebugConsole sharedDebugConsole] performSelector:@selector(sendConsoleAsEmail)];
}

@end

@implementation ESDebugTableViewController
@synthesize applicationLogs=_applicationLogs;
@synthesize segmentedControl=_segmentedControl;

#pragma mark - 

- (void)dealloc
{
	NO_ARC(
		   [_applicationLogs release];
		   [_segmentedControl release];
		   [super dealloc];
		   )
}

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Console";
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	self.segmentedControl = nil;
	self.applicationLogs = nil;
}

#pragma mark - 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.applicationLogs)
		return self.applicationLogs.count;
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"Cell";
	ESDebugTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if (cell == nil)
	{
		cell = [[ESDebugTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
		NO_ARC([cell autorelease];)
	}
	
	ESConsoleEntry *entry = [self.applicationLogs objectAtIndex:indexPath.row];
	cell.applicationIdentifierLabel.text = entry.applicationIdentifier;
	cell.messageLabel.text = entry.shortMessage;
	cell.dateLabel.text = [entry.date description];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	ESDebugDetailViewController *detailViewController = [ESDebugDetailViewController new];
    detailViewController.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
	detailViewController.textView.text = [NSString stringWithFormat:@"%@", [self.applicationLogs objectAtIndex:indexPath.row]];
	[self.navigationController pushViewController:detailViewController animated:YES];
	NO_ARC([detailViewController release];)
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// This assumes that the table view cells content view is as wide as the actual table,
	// which isn't necessarily true, but works fine here
	CGSize size = [[[self.applicationLogs objectAtIndex:indexPath.row] shortMessage] sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 20, 10000) lineBreakMode:UILineBreakModeWordWrap];
	// add in the padding for the applicationIdentifier and date
	size.height += 60;
	return size.height;
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end

@implementation ESDebugTableViewCell
@synthesize applicationIdentifierLabel=_applicationIdentifierLabel;
@synthesize messageLabel=_messageLabel;
@synthesize dateLabel=_dateLabel;

#pragma mark - 

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	if (self != nil)
	{
		_applicationIdentifierLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_applicationIdentifierLabel.font = [UIFont boldSystemFontOfSize:18];
		[self.contentView addSubview:_applicationIdentifierLabel];
		_messageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		_messageLabel.numberOfLines = 0;
		_messageLabel.font = [UIFont systemFontOfSize:17];
		_messageLabel.textColor = [UIColor darkGrayColor];
		[self.contentView addSubview:_messageLabel];
		_dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:_dateLabel];
	}
	return self;
}

- (void)dealloc
{
	NO_ARC(
		   [_applicationIdentifierLabel release];
		   [_messageLabel release];
		   [_dateLabel release];
		   [super dealloc];
		   )
}

#pragma mark - 

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	self.applicationIdentifierLabel.frame = CGRectMake(10, 10, self.contentView.frame.size.width - 20, 18);
	CGSize size = CGSizeMake(self.contentView.frame.size.width - 20, 18);
	if (self.messageLabel.text.length)
		size = [self.messageLabel.text sizeWithFont:[self.messageLabel font] constrainedToSize:CGSizeMake(size.width, 10000) lineBreakMode:UILineBreakModeWordWrap];
	self.messageLabel.frame = CGRectMake(10, 30, size.width, size.height);
	self.dateLabel.frame = CGRectMake(10, CGRectGetMaxY(self.messageLabel.frame), self.contentView.frame.size.width - 20, 18);
}

@end

@implementation ESDebugDetailViewController
@synthesize textView=_textView;

#pragma mark - 

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Details";
	
	self.textView.frame = self.view.bounds;
	
	[self.view addSubview:self.textView];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.textView = nil;
}

#pragma mark -

- (UITextView *)textView
{
	if (_textView == nil)
	{
		_textView = [[UITextView alloc] initWithFrame:CGRectZero];
		_textView.editable = NO;
		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	return _textView;
}

#pragma mark - 

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

@end
