//
//  ViewController.m
//  YawsiOS
//
//  Created by John Holdsworth on 13/06/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import "ViewController.h"
#import "YawsiOS-Swift.h"

@interface ViewController ()
@property IBOutlet UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    id logger = ^ ( NSString *trace ) {
        NSLog( @"%@", trace );
    };

    NSMutableArray *processors = [NSMutableArray new];
    [processors addObject:[[YawsExampleAppProcessor alloc] initWithPathPrefix:@"/example"]];
    [processors addObject:[[YawsSessionProcessor alloc] initWithPathPrefix:@"/ticktacktoe" appClass:[TickTackToe class]]];
    [processors addObject:[[YawsSSLProxyProcessor alloc] initWithLogger:logger]];
    [processors addObject:[[YawsProxyProcessor alloc] initWithLogger:logger]];
    [processors addObject:[[YawsDocumentProcessor alloc] init]];

    (void)[[YawsWebServer alloc] initWithPortNumber:8080 processors:processors localhostOnly:YES];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:8080"]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
