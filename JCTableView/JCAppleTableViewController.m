//
//  JCAppleTableViewController.m
//  JCTableView
//
//  Created by 林锦超 on 15/01/2018.
//  Copyright © 2018 林锦超. All rights reserved.
//

#import "JCAppleTableViewController.h"

@interface JCAppleTableViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray<UIColor *> *colors;
@end

@implementation JCAppleTableViewController

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
    
    self.title = @"UITableView";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle:@"+" style:UIBarButtonItemStylePlain target:self action:@selector(addNewCell:)];
    UIBarButtonItem *minusButton = [[UIBarButtonItem alloc] initWithTitle:@"-" style:UIBarButtonItemStylePlain target:self action:@selector(minusCell:)];
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithTitle:@"re" style:UIBarButtonItemStylePlain target:self action:@selector(reloadCells:)];
    UIBarButtonItem *reloadTotalButton = [[UIBarButtonItem alloc] initWithTitle:@"reload" style:UIBarButtonItemStylePlain target:self action:@selector(reloadTotalCells:)];
    self.navigationItem.rightBarButtonItems = @[ reloadTotalButton, reloadButton, minusButton, addButton ];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tableView.frame = self.view.bounds;
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        NSIndexPath *index = [NSIndexPath indexPathForRow:0 inSection:0];
//        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:index];
//        NSLog(@"cell.subviews:%@", cell.subviews);
//    });
}

- (UIColor *)randomColor
{
    CGFloat r = rand() / (float)INT_MAX;
    CGFloat g = rand() / (float)INT_MAX;
    CGFloat b = rand() / (float)INT_MAX;
    return [UIColor colorWithRed:r green:g blue:b alpha:1.f];
}

#pragma mark - Getter
- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero];
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
    row0 = 0;
    row1 = 2;
    NSMutableIndexSet *set = [NSMutableIndexSet new];
    [set addIndex:row0];
    [set addIndex:row1];
    [self.colors insertObjects:@[ [UIColor blackColor], [UIColor blackColor] ] atIndexes:set ];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row0 inSection:0];
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:row1 inSection:0];
    
    CFTimeInterval timeStart = CACurrentMediaTime();
    [self.tableView insertRowsAtIndexPaths:@[ indexPath , indexPath1 ] withRowAnimation:UITableViewRowAnimationFade];
    // 0.004151
    NSLog(@"insertRowsAtIndexPaths timeEclips:%f", CACurrentMediaTime() - timeStart);
}

- (IBAction)minusCell:(id)sender
{
    NSInteger row0 = 0;
    NSInteger row1 = 2;
    NSMutableIndexSet *set = [NSMutableIndexSet new];
    [set addIndex:row0];
    [set addIndex:row1];
    [self.colors removeObjectsAtIndexes:set];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row0 inSection:0];
    NSIndexPath *indexPath1 = [NSIndexPath indexPathForRow:row1 inSection:0];
    
    CFTimeInterval timeStart = CACurrentMediaTime();
    [self.tableView deleteRowsAtIndexPaths:@[ indexPath , indexPath1 ] withRowAnimation:UITableViewRowAnimationNone];
    // 0.004151
    NSLog(@"deleteRowsAtIndexPaths timeEclips:%f", CACurrentMediaTime() - timeStart);
}

- (IBAction)reloadCells:(id)sender
{
    NSIndexPath *firstIndex = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *secondIndex = [NSIndexPath indexPathForRow:2 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[ firstIndex, secondIndex ] withRowAnimation:UITableViewRowAnimationBottom];
}

- (IBAction)reloadTotalCells:(id)sender
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
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.colors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%zd-%zd", indexPath.section, indexPath.row];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor = self.colors[indexPath.row];
    return cell;
}

#pragma mark - JCTableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.f;
}

//MARK: Editing
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
// 定义编辑样式
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}
// 进入编辑模式，按下出现的编辑按钮后,进行删除操作
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"是否确认删除？" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.colors removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

//修改编辑按钮文字
//- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return @"删除";
//}
@end
