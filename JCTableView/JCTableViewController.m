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
@property (nonatomic, strong) NSArray<UIColor *> *colors;
@end

@implementation JCTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _colors = @[ [UIColor redColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [self randomColor],
                 [UIColor greenColor]];
    
    self.title = @"JCTableView";
    self.view.backgroundColor = [UIColor whiteColor];
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
    cell.backgroundColor = self.colors[indexPath.row];
    return cell;
}

#pragma mark - JCTableViewDelegate
- (CGFloat)tableView:(JCTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.f;
}

@end
