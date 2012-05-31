//
//  LFCViewController.m
//  LFC-test
//
//  Created by Thomas Goyne on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LFCViewController.h"

#import "LivefyreTest.h"

@interface LFCViewController () < LogSink >
@property (weak, nonatomic) IBOutlet UITextView *display;
@property (strong, nonatomic) LivefyreTest *tester;
@end

@implementation LFCViewController
@synthesize display = display_;
@synthesize tester = tester_;

- (LivefyreTest *)tester {
    if (!tester_) {
        tester_ = [[LivefyreTest alloc] initWithLogger:self];
        tester_.userName = @"dev01";
        tester_.articleId = @"test-article-id";
    }
    return tester_;
}

- (void)logWithFormat:(NSString *)format, ... {
    va_list va;
    va_start(va, format);
    self.display.text = [self.display.text stringByAppendingString:[[NSString alloc] initWithFormat:format arguments:va]];
    va_end(va);
}

- (void)log:(NSString *)message {
    self.display.text = [self.display.text stringByAppendingString:message];
}

- (void)clear {
    self.display.text = @"";
}

- (IBAction)userNameChanged:(UITextField *)sender {
    self.tester.userName = sender.text;
}

- (IBAction)articleChanged:(UITextField *)sender {
    self.tester.articleId = sender.text;
}

- (IBAction)createCollection {
    [self.tester createCollection];
}

- (IBAction)authenticate {
    [self.tester authenticate];
}

- (IBAction)initMetaData {
    [self.tester getCollectionData];
}

- (IBAction)startPolling {
    [self.tester startPolling];
}

- (IBAction)stopPolling {
    [self.tester stopPolling];
}

@end
