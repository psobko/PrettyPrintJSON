//
//  PrettyPrintJSON.h
//  PrettyPrintJSON
//
//  Created by psobko on 5/5/15.
//  Copyright (c) 2015 psobko. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface PrettyPrintJSON : NSObject
//
+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end