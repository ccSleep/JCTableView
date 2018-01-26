//
//  JCTableSectionViewController.m
//  JCTableView
//
//  Created by 林锦超 on 25/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCTableSectionViewController.h"

@interface JCTableSectionViewController ()<JCTableViewDataSource, JCTableViewDelegate>
@property (nonatomic, strong) JCTableView *tableView;
@property (nonatomic, strong) NSMutableArray<NSMutableArray<UIColor *> *> *colors;
@end

@implementation JCTableSectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _colors = [@[ [ @[[UIColor redColor], [self randomColor]] mutableCopy],
                  [ @[[self randomColor]] mutableCopy],
                  [ @[[self randomColor], [self randomColor]] mutableCopy],
                  [ @[[self randomColor]] mutableCopy],
                  [ @[[self randomColor]] mutableCopy],
                  [ @[[self randomColor]] mutableCopy],
                  [ @[[self randomColor]] mutableCopy],
                  [ @[[UIColor greenColor]] mutableCopy], ] mutableCopy];
    
    self.title = @"JCTableView-Section";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStylePlain target:self action:@selector(addNewCell:)];
    UIBarButtonItem *minusButton = [[UIBarButtonItem alloc] initWithTitle:@"-" style:UIBarButtonItemStylePlain target:self action:@selector(minusCell:)];
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithTitle:@"reload" style:UIBarButtonItemStylePlain target:self action:@selector(reloadCells:)];
    self.navigationItem.rightBarButtonItems = @[ reloadButton, minusButton, addButton ];
    
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
        [_tableView registerClass:[JCTableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

#pragma mark - Action
- (IBAction)addNewCell:(id)sender
{
    NSInteger section0 = 0;
    NSInteger section1 = 2;
    [self.colors[section0] insertObject:[UIColor blackColor] atIndex:0];
    [self.colors[section1] insertObject:[UIColor blackColor] atIndex:0];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section0];
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:0 inSection:section1];
    [self.tableView insertRowsAtIndexPaths:@[ indexPath, indexPath1 ] withRowAnimation:JCTableViewRowAnimationFade];
}

- (IBAction)minusCell:(id)sender
{
    NSInteger section0 = 0;
    NSInteger section1 = 2;
    [self.colors[section0] removeObjectAtIndex:0];
    [self.colors[section1] removeObjectAtIndex:0];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section0];
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:0 inSection:section1];
    
    CFTimeInterval timeStart = CACurrentMediaTime();
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath, indexPath1 ] withRowAnimation:JCTableViewRowAnimationTop];
    // 0.004151
    NSLog(@"deleteRowsAtIndexPaths timeEclips:%f", CACurrentMediaTime() - timeStart);
}

- (IBAction)reloadCells:(id)sender
{
    NSIndexPath *firstIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *secondIndex = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView reloadRowsAtIndexPaths:@[ firstIndex, secondIndex ] withRowAnimation:JCTableViewRowAnimationBottom];
}

#pragma mark - JCTableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(JCTableView *)tableView
{
    return self.colors.count;
}

- (NSInteger)tableView:(nonnull JCTableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.colors[section].count;
}

- (nonnull JCTableViewCell *)tableView:(nonnull JCTableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    JCTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
//    if (!cell) {
//        cell = [[JCTableViewCell alloc] initWithReuseIdentifier:@"cell"];
//    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd-%zd", indexPath.section, indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = self.colors[indexPath.section][indexPath.row];
    return cell;
}

#pragma mark - JCTableViewDelegate
- (CGFloat)tableView:(JCTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.f;
}

// Editing
- (BOOL)tableView:(JCTableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (void)tableView:(JCTableView *)tableView commitEditingForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"是否确认删除？" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.colors removeObjectAtIndex:indexPath.section];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:JCTableViewRowAnimationTop];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}
@end
