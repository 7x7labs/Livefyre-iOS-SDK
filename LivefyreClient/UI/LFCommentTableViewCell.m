//
//  CommentTableViewCell.m
//  LivefyreClient
//
//  Created by Thomas Goyne on 9/17/12.
//
//

#import "LFCommentTableViewCell.h"

#import <LivefyreClient/LivefyreClient.h>

@interface LFCommentTableViewCell () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *authorName;
@property (weak, nonatomic) IBOutlet UILabel *timestamp;
@property (weak, nonatomic) IBOutlet UIWebView *body;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@property (weak, nonatomic) IBOutlet UIView *border;
@property (weak, nonatomic) IBOutlet UIView *background;

@property (strong, nonatomic) NSString *contentId;
@property (strong, nonatomic) NSMutableDictionary *pendingRequests;
@property (assign, nonatomic) NSInteger requestsStarted;
@end

@implementation LFCommentTableViewCell
- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect frame = self.contentView.frame;
    frame.origin.x = self.indentationLevel * self.indentationWidth - 1;
    frame.size.width -= frame.origin.x;
    self.contentView.frame = frame;
    self.border.frame = CGRectMake(0, 0, 320, frame.size.height);
    self.background.frame = CGRectMake(1, 0, 320, frame.size.height - 1);
    self.body.frame = CGRectMake(9, 34, frame.size.width - 16, frame.size.height - self.body.frame.origin.y - 1);
    self.avatar.frame = CGRectMake(9, 9, 25, 25);
    self.authorName.frame = CGRectMake(38, 10, 262, 12);
    self.timestamp.frame = CGRectMake(38, 25, 262, 12);
}

- (void)setToPost:(Post *)post {
    self.body.scrollView.scrollEnabled = NO;
    self.body.scrollView.bounces = NO;

    self.contentId = post.contentId;
    self.authorName.text = post.author.displayName;
    self.timestamp.text = [[NSDate dateWithTimeIntervalSince1970:post.editedAt] relativeTime];
    [self.body loadHTMLString:[self styleBody:post.body] baseURL:nil];
    [self.delegate setImageView:self.avatar toImageAtURL:post.author.avatarUrl];

    self.body.delegate = self;
    self.indentationLevel = 0;
    Content *parent = post.parent;
    while (parent) {
        ++self.indentationLevel;
        parent = parent.parent;
    }

    ++self.requestsStarted;
    if (!self.pendingRequests) {
        self.pendingRequests = [NSMutableDictionary new];
    }
    self.pendingRequests[post.body] = post.contentId;
}

- (NSString *)styleBody:(NSString *)body {
    NSString *template = @"\
        <html>\
            <head>\
                <style type='text/css'>\
                    body {\
                        font-family: HelveticaNeue;\
                        font-size: 14px;\
                        margin: 7px 0;\
                        color: #7f7f7f;\
                        line-height: 17px;\
                    }\
                    p {\
                        margin: 0;\
                    }\
                    a {\
                        font-family: HelveticaNeue-Medium;\
                        text-decoration: none;\
                        color: #1a7fe7;\
                    }\
                </style>\
            </head>\
            <body>\
                <div id='wrapper'>\
                    %@\
                </div>\
                <script type='text/javascript'>\
                document.getElementById('wrapper').onclick = function(e) {\
                    for (var node = e.target; node; node = node.parentNode) {\
                        if (node.nodeName == 'A') {\
                            return true;\
                        }\
                    }\
                    window.location = 'click://body';\
                    return false;\
                }\
                </script>\
            </body>\
        </html>";

    return [NSString stringWithFormat:template, body];
}

// Update the size of the view to fit the contents
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *contentId = self.contentId;
    if (--self.requestsStarted != 0) {
        // If more requests have been started than completed, this might be the
        // completion for a request other than the most recent one
        NSString *html = [[webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        contentId = self.pendingRequests[html];
        if (!contentId) return;

        // Just got the most recent request, so any other were probably dropped
        if (contentId == self.contentId) {
            self.requestsStarted = 0;
            [self.pendingRequests removeAllObjects];
        }
    }
    else {
        [self.pendingRequests removeAllObjects];
    }

    CGFloat height = webView.frame.size.height;

    // sizeThatFits never returns a size smaller than the current size
    CGRect frame = webView.frame;
    frame.size.height = 1;
    webView.frame = frame;

    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
    if (height != fittingSize.height) {
        [self.delegate postWithId:contentId hasHeight:webView.frame.origin.y + fittingSize.height + 1];
    }

    frame.size.height = height;
    webView.frame = frame;
}

// Make any links touched open in Safari rather than in the comment view
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] scheme] isEqualToString:@"click"]) {
        [self.delegate didReceieveTapOnPost:self.contentId];
        return NO;
    }

    if (navigationType == UIWebViewNavigationTypeOther)
        return YES;

    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
}
@end
