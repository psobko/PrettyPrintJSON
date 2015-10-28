//
//  PrettyPrintJSON.m
//  PrettyPrintJSON
//
//  Created by psobko on 5/5/15.
//  Copyright (c) 2015 psobko. All rights reserved.
//

#import "PrettyPrintJSON.h"
#import "IDEKit.h"

static PrettyPrintJSON *sharedPlugin;

@interface PrettyPrintJSON()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@end

@implementation PrettyPrintJSON

+ (void)pluginDidLoad:(NSBundle *)plugin
{
  static dispatch_once_t onceToken;
  NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
  
  if ([currentApplicationName isEqual:@"Xcode"])
  {
    dispatch_once(&onceToken, ^{
      sharedPlugin = [[self alloc] initWithBundle:plugin];
      
      dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMenu *editorMenu = [[[NSApp mainMenu] itemWithTitle:@"Edit"] submenu];
        
        if (!editorMenu) return;
        
        NSString *versionString = [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSMenuItem *prettyMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Pretty Print JSON (%@)", versionString]
                                                                action:@selector(menuItemSelected:)
                                                         keyEquivalent:@"j"];
        
        prettyMenuItem.target = sharedPlugin;
        prettyMenuItem.keyEquivalentModifierMask = NSControlKeyMask;
        
        [editorMenu addItem:prettyMenuItem];
      });
    });
  }
}

#pragma mark - init

+ (instancetype)sharedPlugin
{
  return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
  if (self = [super init])
  {
    self.bundle = plugin;
  }
  return self;
}

- (void)menuItemSelected:(id)sender
{
  NSView *contentView = [[NSApp mainWindow] contentView];
  IDEConsoleTextView *consoleTextView = (IDEConsoleTextView *)[self getViewByClassName:@"IDEConsoleTextView" andContainerView:contentView];
  NSRange range = [consoleTextView selectedRange];
  consoleTextView.logMode = 1;
  [consoleTextView insertText:[self prettyPrintedJSONForString:[consoleTextView.string substringWithRange:range]]];
  [consoleTextView insertNewline:@""];
  consoleTextView.logMode = 0;
}

- (NSView *)getViewByClassName:(NSString *)className andContainerView:(NSView *)container
{
  Class class = NSClassFromString(className);
  for (NSView *subView in container.subviews) {
    if ([subView isKindOfClass:class]) {
      return subView;
    } else {
      NSView *view = [self getViewByClassName:className andContainerView:subView];
      if ([view isKindOfClass:class]) {
        return view;
      }
    }
  }
  return nil;
}

-(NSString*)prettyPrintedJSONForString:(NSString *)uglyString
{
  if(!uglyString)
  {
    return [NSString stringWithFormat:@"JSON Parse Error: No string selected"];
  }
  
  NSError *error;
  id data = [NSJSONSerialization JSONObjectWithData:[uglyString dataUsingEncoding:NSUTF8StringEncoding]
                                            options:0
                                              error:&error];
  
  if(error)
  {
    return [NSString stringWithFormat:@"JSON Parse Error: %@ %@", error.localizedDescription, [error.userInfo objectForKey:@"NSDebugDescription"]];
  }
  
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                     options:(NSJSONWritingOptions)NSJSONWritingPrettyPrinted
                                                       error:&error];
  if(error)
  {
    return [NSString stringWithFormat:@"JSON Parse Error: %@ %@", error.localizedDescription, [error.userInfo objectForKey:@"NSDebugDescription"]];
  }
  
  return (jsonData) ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"{}";
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
