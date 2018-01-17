//
//  JCRootViewController.m
//  JCTableView
//
//  Created by 林锦超 on 15/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCRootViewController.h"
#import "JCAppleTableViewController.h"
#import "JCTableViewController.h"

static NSString *kCellIdentifier = @"kCellIdentifier";

@interface JCRootViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *datas;
@end

@implementation JCRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.datas = @[ @"UITableView", @"JCTableView"];
    
    self.navigationItem.title = @"JCTableViewDemo";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor yellowColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    cell.textLabel.text = self.datas[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        JCAppleTableViewController *appleVC = [[JCAppleTableViewController alloc] init];
        [self.navigationController pushViewController:appleVC animated:YES];
    }
    else if (indexPath.row == 1) {
        JCTableViewController *customVC = [[JCTableViewController alloc] init];
        [self.navigationController pushViewController:customVC animated:YES];
    }
}

@end
