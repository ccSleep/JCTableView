//
//  ViewController.m
//  JCTableView
//
//  Created by 林锦超 on 11/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableViewController.h"
#import "JCTableView.h"

@interface JCTableViewController ()<JCTableViewDataSource, JCTableViewDelegate>
@property (nonatomic, strong) JCTableView *tableView;
@property (nonatomic, strong) NSMutableArray<UIColor *> *colors;
@end

@implementation JCTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _colors = [@[ [UIColor redColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [UIColor greenColor]] mutableCopy];
    
    self.title = @"JCTableView";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewCell:)];
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadCells:)];
    self.navigationItem.rightBarButtonItems = @[ reloadButton, addButton ];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

- (UIColor *)randomColor
{
    CGFloat r = rand() / (float)INT_MAX;
    CGFloat g = rand() / (float)INT_MAX;
    CGFloat b = rand() / (float)INT_MAX;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.f];
}

#pragma mark - Getter
- (JCTableView *)tableView
{
    if (!_tableView) {
        _tableView = [[JCTableView alloc] initWithFrame:CGRectZero];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor whiteColor];
    }
    return _tableView;
}

#pragma mark - Action
- (IBAction)addNewCell:(id)sender
{
    NSInteger row0 = random() % self.colors.count;
    NSInteger row1 = random() % self.colors.count;
    NSMutableIndexSet *set = [NSMutableIndexSet new];
    row0 = 0;
    row1 = 2;
    [set addIndex:row0];
    [set addIndex:row1];
    [self.colors insertObjects:@[ [UIColor blackColor], [UIColor blackColor] ] atIndexes:set];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row0 inSection:0];
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:row1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[ indexPath1, indexPath ] withRowAnimation:JCTableViewRowAnimationFade];
    
    /*
    NSInteger row = 0;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [self.colors insertObject:[UIColor blackColor] atIndex:row];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:JCTableViewRowAnimationFade];
    */
    
}

- (IBAction)reloadCells:(id)sender
{
//    NSIndexPath *firstIndex = [NSIndexPath indexPathForRow:0 inSection:0];
//    NSIndexPath *secondIndex = [NSIndexPath indexPathForRow:1 inSection:0];
//    NSIndexPath *thirdIndex = [NSIndexPath indexPathForRow:2 inSection:0];
//
//    NSLog(@"start first Cell0:%@", [self.tableView cellForRowAtIndexPath:firstIndex]);
//    NSLog(@"start first Cell1:%@", [self.tableView cellForRowAtIndexPath:secondIndex]);
//    NSLog(@"start first Cell2:%@", [self.tableView cellForRowAtIndexPath:thirdIndex]);
    
    [self.colors insertObject:[UIColor blackColor] atIndex:1];
    [self.tableView reloadData];
    
//    NSLog(@"end first Cell0:%@", [self.tableView cellForRowAtIndexPath:firstIndex]);
//    NSLog(@"end first Cell1:%@", [self.tableView cellForRowAtIndexPath:secondIndex]);
//    NSLog(@"end first Cell2:%@", [self.tableView cellForRowAtIndexPath:thirdIndex]);
}

#pragma mark - JCTableViewDataSource
- (NSInteger)tableView:(nonnull JCTableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.colors.count;
}

- (nonnull JCTableViewCell *)tableView:(nonnull JCTableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    JCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[JCTableViewCell alloc] initWithReuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd-%zd", indexPath.section, indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = self.colors[indexPath.row];
    return cell;
}

#pragma mark - JCTableViewDelegate
- (CGFloat)tableView:(JCTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.f;
}

- (void)tableView:(JCTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath:%@", indexPath);
}

- (void)tableView:(JCTableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didDeselectRowAtIndexPath:%@", indexPath);
}

@end
