//
//  ViewController.m
//  NSCondition
//
//  Created by humiao on 2018/12/29.
//  Copyright © 2018年 humiao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSMutableArray *products;
    NSCondition *condition;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self hm_Condition];
    
    [self hm_Thread];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)hm_Condition {
    
    NSCondition *hmCondition = [[NSCondition  alloc] init];
    NSMutableArray *product = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [hmCondition lock];
        while ([product count] == 0) {
            NSLog(@"wait for product");
            [hmCondition wait];
        }
        [product removeObjectAtIndex:0];
        NSLog(@"custome a product");
        [hmCondition  unlock];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [hmCondition lock];
        [product addObject:[[NSObject alloc] init]];
        NSLog(@"produce a product");
        [hmCondition signal];
        [hmCondition  unlock];
    });
}

- (void)hm_Thread {
    
    static void (^myBlock)(int);
    
    myBlock = ^(int a) {
        a--;
        NSLog(@"当前的值:%d",a);
        if (a > 0) {
            myBlock(a);
        }
    };
    
    myBlock(5);
}


- (IBAction)lock:(id)sender {
    
//    NSLock *lock = [[NSLock alloc] init];
//    它可以允许同一线程多次加锁，而不会造成死锁。递归锁会跟踪它被lock的次数。
   NSRecursiveLock *lock = [[NSRecursiveLock alloc] init]; dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        static void (^RecursiveMethod)(int);
        
        RecursiveMethod = ^(int value) {
            
            [lock lock];
            if (value > 0) {
                
                NSLog(@"value = %d", value);
                sleep(2);
                RecursiveMethod(value - 1);
            }
            [lock unlock];
        };
        
        RecursiveMethod(5);
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        sleep(2);
        BOOL flag = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        if (flag) {
            NSLog(@"lock before date");
            
            [lock unlock];
        } else {
            NSLog(@"fail to lock before date");
        }
    });
}

- (IBAction)GCD:(id)sender {
    dispatch_group_t group = dispatch_group_create();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(10);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (int i = 0; i < 100; i++)
    {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_group_async(group, queue, ^{
            NSLog(@"%i",i);
            sleep(2);
            dispatch_semaphore_signal(semaphore);
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (IBAction)condition:(id)sender {
    NSLog(@"begin condition works!");
    products = [[NSMutableArray alloc] init];
    condition = [[NSCondition alloc] init];
    
    [NSThread detachNewThreadSelector:@selector(createProducter) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(createConsumenr) toTarget:self withObject:nil];
}

- (void)createConsumenr
{
    [condition lock];
    while ([products count] == 0) {
        NSLog(@"wait for products");
        [condition wait];
    }
    [products removeObjectAtIndex:0];
    NSLog(@"comsume a product");
    [condition unlock];
}

- (void)createProducter
{
    [condition lock];
    [products addObject:[[NSObject alloc] init]];
    NSLog(@"produce a product");
    [condition signal];
    [condition unlock];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
