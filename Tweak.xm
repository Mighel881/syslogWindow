static BOOL hasstarted = NO;
@interface UIWindow (log)
- (id)firstResponder;
@end
@interface LogWindow: UIWindow

@end

@implementation LogWindow
- (BOOL)_ignoresHitTest {
  return YES;
}
@end

@interface UIPassThroughLabel : UILabel
@end

@implementation UIPassThroughLabel
- (BOOL)_ignoresHitTest {
  return YES;
}
@end

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();
static UIPassThroughLabel *l;
static LogWindow *logWindow = nil;
static NSMutableArray* msgs = nil;

static void shareSnap(CFNotificationCenterRef center, 
                        void *observer, 
                        CFStringRef name, 
                        const void *object, 
                        CFDictionaryRef userInfo) {

    // Since we're doing UI stuff, let's just wait for the SB to
    // boot up for sure
    if(hasstarted == NO){
      return;
    }

    // Init if needed
    if(msgs==nil){
      msgs = [[NSMutableArray alloc] init];
    }

    // Only save the 10 latest messages
    [msgs addObject:[((NSDictionary*)userInfo) objectForKey:@"message"]];
    if([msgs count]>10){
      [msgs removeObjectAtIndex:0];
    }

    if( logWindow == nil ){
      logWindow = [[LogWindow alloc] init];//WithFrame:[UIScreen mainScreen].bounds];
      logWindow.backgroundColor = [UIColor clearColor];
      //logWindow.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.25f];
      logWindow.userInteractionEnabled = YES;
      [logWindow setWindowLevel:UIWindowLevelStatusBar+10000];
     // [logWindow makeKeyAndVisible];
      logWindow.hidden = NO;
      l = [[UIPassThroughLabel alloc] initWithFrame:CGRectMake(1,1,318,200)];
      l.textAlignment = NSTextAlignmentLeft;
      l.userInteractionEnabled = NO;
      l.adjustsFontSizeToFitWidth = YES;
      l.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.75f];
      l.textColor = [UIColor whiteColor];
      l.numberOfLines = 0;
      [logWindow addSubview:l];
    }

    // Scroll to bottom
    NSString *ss=@"";
    for(NSString *s in msgs){
      ss = [ss stringByAppendingString:s];
      ss = [ss stringByAppendingString:@"\n"];
    }
    [l setText:ss];
}

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter();
extern "C" int startTheSyslogThingy();

%hook SBUIController
-(void)finishLaunching{
   %orig();
   hasstarted = YES;
}
%end

%ctor{
    CFNotificationCenterAddObserver(
                            CFNotificationCenterGetDistributedCenter(), 
                            NULL, 
                            (CFNotificationCallback)shareSnap, 
                            CFSTR("com.jontelang.snapper2.sharesnap2GRR"), 
                            NULL, 
                            CFNotificationSuspensionBehaviorCoalesce);

    dispatch_queue_t backgroundQueue = dispatch_queue_create("bgsyslogqueueu", 0);
    dispatch_async(backgroundQueue, ^{
        startTheSyslogThingy();
    });

}