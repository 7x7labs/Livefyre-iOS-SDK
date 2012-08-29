//
//  CommentTableViewCell.h
//  LivefyreClient
//
//  Created by Thomas Goyne on 9/17/12.
//
//

#import <UIKit/UIKit.h>

@class Post;

@class LFCommentTableViewCell;
@protocol LFCommentTableViewCellDelegate <NSObject>
- (void)postWithId:(NSString *)contentId hasHeight:(CGFloat)height;
- (void)setImageView:(UIImageView *)view toImageAtURL:(NSString *)url;
@end

@interface LFCommentTableViewCell : UITableViewCell
@property (weak, nonatomic) id<LFCommentTableViewCellDelegate> delegate;

- (void)setToPost:(Post *)post;
@end
