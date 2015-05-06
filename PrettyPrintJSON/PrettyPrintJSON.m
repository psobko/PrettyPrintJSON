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
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        if (menuItem)
        {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Pretty Print JSON"
                                                                    action:@selector(menuItemSelected)
                                                             keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [actionMenuItem setKeyEquivalent:@"j"];
            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];
            [[menuItem submenu] addItem:actionMenuItem];
        }
    }
    return self;
}

- (void)menuItemSelected
{
    for (NSWindow *window in [NSApp windows])
    {
        NSView *contentView = window.contentView;
        IDEConsoleTextView *console = [self consoleViewInMainView:contentView];
        NSRange range = [console selectedRange];
        console.logMode = 1;
        [console insertText:[self prettyPrintedJSONForString:[console.string substringWithRange:range]]];
        [console insertNewline:@""];
        console.logMode = 0;
    }
}

- (IDEConsoleTextView *)consoleViewInMainView:(NSView *)mainView
{
    for (NSView *childView in mainView.subviews)
    {
        if ([childView isKindOfClass:NSClassFromString(@"IDEConsoleTextView")])
        {
            return (IDEConsoleTextView *)childView;
        }
        else
        {
            NSView *consoleView = [self consoleViewInMainView:childView];
            if ([consoleView isKindOfClass:NSClassFromString(@"IDEConsoleTextView")])
            {
                return (IDEConsoleTextView *)consoleView;
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