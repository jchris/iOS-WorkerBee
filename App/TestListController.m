//
//  TestListController.m
//  Worker Bee
//
//  Created by Jens Alfke on 10/4/11.
//  Copyright (c) 2011 Couchbase, Inc. All rights reserved.
//

#import "TestListController.h"
#import "AppDelegate.h"
#import "BeeTest.h"
#import "BeeTestController.h"
#import "SavedTestRun.h"


static NSString* const kUpstreamSavedTestDatabaseURL =
                                @"http://ec2-50-16-117-7.compute-1.amazonaws.com:5984/ios-tests/";


@interface TestListController ()
- (void) updateSavedTestUI;
@end


@implementation TestListController
{
    NSMutableDictionary* _activeTestByClass;
}

static UIColor* kBGColor;

+ (void) initialize {
    if (self == [TestListController class]) {
        if (!kBGColor)
            kBGColor = [[UIColor colorWithPatternImage: [UIImage imageNamed:@"double_lined.png"]] 
                        retain];
    }
}

@synthesize testList = _testList, tableView = _tableView, savedRunCountLabel = _savedRunCountLabel,
            uploadButton = _uploadButton, forgetButton = _forgetButton;

- (void)dealloc {
    [_testList release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!_testList) {
        _testList = [[BeeTest allTestClasses] copy];
        _activeTestByClass = [[NSMutableDictionary alloc] init];
    }

    // Use short name "Tests" in the back button leading to this view
    UIBarButtonItem* backItem = [[UIBarButtonItem alloc] init];
    backItem.title = @"Tests";
    self.navigationItem.backBarButtonItem = backItem;
    [backItem release];

    [self.tableView setBackgroundView:nil];
    [self.tableView setBackgroundColor: [UIColor clearColor]];
    [self.view setBackgroundColor:kBGColor];
    
    [_savedRunCountLabel setHidden: YES];
    [_uploadButton setHidden: YES];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(serverStarted)
                                                 name: AppDelegateCouchStartedNotification
                                               object: nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateSavedTestUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void) serverStarted {
    [self updateSavedTestUI];
}

- (void) updateSavedTestUI {
    NSString* text;
    int nSaved = [SavedTestRun savedTestCount];
    if (nSaved == 1)
        text = @"one saved test run";
    else
        text = [NSString stringWithFormat: @"%u saved test runs", nSaved];
    _savedRunCountLabel.text = text;
    _savedRunCountLabel.hidden = _uploadButton.hidden = _forgetButton.hidden = (nSaved == 0);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSAssert(_testList, @"didn't load test list");
    return _testList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:CellIdentifier] autorelease];
        UISwitch* sw = [[UISwitch alloc] init];
        cell.accessoryView = sw;
        [sw addTarget: self action: @selector(startStopTest:) forControlEvents: UIControlEventValueChanged];
        [sw release];
    }
    
    Class testClass = [_testList objectAtIndex: indexPath.row];
    BeeTest* existingTest = [self testForClass: testClass];
    cell.textLabel.text = [testClass displayName];
    UISwitch* sw = (UISwitch*)cell.accessoryView;
    sw.on = existingTest.running;
    sw.tag = indexPath.row;
    return cell;
}


#pragma mark - Table view delegate

- (BeeTest*) testForClass: (Class)testClass {
    return [_activeTestByClass objectForKey: [testClass testName]];
}

- (BeeTest*) makeTestForClass: (Class)testClass {
    BeeTest* test = [self testForClass: testClass];
    if (!test) {
        test = [[[testClass alloc] init] autorelease];
        if (test) {
            [_activeTestByClass setObject: test forKey: [testClass testName]];
            [test addObserver: self forKeyPath: @"running" options: 0 context: NULL];
        }
    }
    return test;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class testClass = [_testList objectAtIndex: indexPath.row];
    BeeTest* test = [self makeTestForClass: testClass];
    if (!test)
        return; // TODO: Show an alert
    BeeTestController *testController = [[BeeTestController alloc] initWithTest: test];
    [self.navigationController pushViewController:testController animated:YES];
    [testController release];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object 
                         change:(NSDictionary *)change
                        context:(void *)context
{
    if ([object isKindOfClass: [BeeTest class]]) {
        // Test "running" state changed:
        BOOL running = [object running];
        Class testClass = [object class];
        NSUInteger index = [_testList indexOfObjectIdenticalTo: testClass];
        NSAssert(index != NSNotFound, @"Can't find %@", object);
        NSIndexPath* path = [NSIndexPath indexPathForRow: index inSection: 0];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath: path];
        UISwitch* sw = (UISwitch*)cell.accessoryView;
        [sw setOn: running animated: YES];
        if (!running)
            [self updateSavedTestUI];
    }
}

- (IBAction) startStopTest:(id)sender {
    Class testClass = [_testList objectAtIndex: [sender tag]];
    BeeTest* test = [self makeTestForClass: testClass];
    BOOL running = [sender isOn];
    NSLog(@"Setting %@ running=%i", test, running);
    if (!running)
        test.stoppedByUser = YES;
    test.running = running;
}

- (IBAction) uploadSavedRuns:(id)sender {
    NSURL* url = [NSURL URLWithString: kUpstreamSavedTestDatabaseURL];
    NSError* error;
    if ([SavedTestRun uploadAllTo: url error: &error])
        [self updateSavedTestUI];
    else {
        NSLog(@"ERROR: Upload failed: %@", error);
        NSString* message = [NSString stringWithFormat: @"Couldn't upload saved test results: %@."
                                                         "\n\nPlease try again later.",
                                                        error.localizedDescription];
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Upload Failed"
                                                        message: message
                                                       delegate: nil
                                              cancelButtonTitle: @"Sorry"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
}

- (IBAction) forgetSavedRuns:(id)sender {
    [SavedTestRun forgetAll: nil];
    [self updateSavedTestUI];
}

@end
