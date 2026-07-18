//
//  TISInputSource.m
//  Gureum
//
//  Created by Jeong YunWon on 2014. 10. 29..
//  Copyright (c) 2014년 youknowone.org. All rights reserved.
//

#import "TISInputSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface TISInputSourceError : NSError

- (instancetype)initWithCode:(OSStatus)err NS_DESIGNATED_INITIALIZER;
+ (instancetype)errorWithCode:(OSStatus)err;

@end

@implementation TISInputSourceError

- (instancetype)initWithCode:(OSStatus)err {
    return [super initWithDomain:@"TISInputSource" code:err userInfo:@{}];
}

+ (instancetype)errorWithCode:(OSStatus)err {
    return [[self alloc] initWithCode:err];
}

@end


@interface TISInputSource ()

- (instancetype)initWithRef:(TISInputSourceRef)ref;

@end


@implementation TISInputSource

@synthesize ref=_ref;

- (instancetype)init {
    return nil;
}

- (instancetype)initWithRef:(TISInputSourceRef)ref {
    self = [super init];
    if (self != nil) {
        CFRetain(ref);
        self->_ref = ref;
    }
    return self;
}

- (void)dealloc {
    if (self->_ref) {
        CFRelease(self->_ref);
    }
}

- (nullable id)propertyForKey:(NSString *)key {
    return (__bridge id)TISGetInputSourceProperty(self->_ref, (__bridge CFStringRef)key);
}

- (NSString *)category {
    return [self propertyForKey:TISPropertyInputSourceCategory] ?: @"";
}

- (NSString *)type {
    return [self propertyForKey:TISPropertyInputSourceType] ?: @"";
}

- (BOOL)ASCIICapable {
    id value = [self propertyForKey:TISPropertyInputSourceIsASCIICapable];
    return value != nil ? CFBooleanGetValue((__bridge CFBooleanRef)value) : NO;
}

- (BOOL)enableCapable {
    id value = [self propertyForKey:TISPropertyInputSourceIsEnableCapable];
    return value != nil ? CFBooleanGetValue((__bridge CFBooleanRef)value) : NO;
}

- (BOOL)selectCapable {
    id value = [self propertyForKey:TISPropertyInputSourceIsSelectCapable];
    return value != nil ? CFBooleanGetValue((__bridge CFBooleanRef)value) : NO;
}

- (BOOL)enabled {
    id value = [self propertyForKey:TISPropertyInputSourceIsEnabled];
    return value != nil ? CFBooleanGetValue((__bridge CFBooleanRef)value) : NO;
}

- (BOOL)selected {
    id value = [self propertyForKey:TISPropertyInputSourceIsSelected];
    return value != nil ? CFBooleanGetValue((__bridge CFBooleanRef)value) : NO;
}

- (NSString *)identifier {
    return [self propertyForKey:TISPropertyInputSourceID] ?: @"";
}

- (NSString *)bundleIdentifier {
    return [self propertyForKey:TISPropertyBundleID] ?: @"";
}

- (NSString *)inputModeIdentifier {
    return [self propertyForKey:TISPropertyInputModeID] ?: @"";
}

- (NSString *)localizedName {
    return [self propertyForKey:TISPropertyLocalizedName] ?: [self identifier];
}

- (NSArray *)languages {
    return [self propertyForKey:TISPropertyInputSourceLanguages] ?: @[];
}

- (NSData * _Nullable)layoutData {
    return [self propertyForKey:TISPropertyUnicodeKeyLayoutData];
}

- (NSURL * _Nullable)iconImageURL {
    return [self propertyForKey:TISPropertyIconImageURL];
}

+ (nullable instancetype)sourceForLanguage:(NSString *)language {
    TISInputSourceRef ref = TISCopyInputSourceForLanguage((__bridge CFStringRef)language);
    if (ref == NULL) {
        return nil;
    }
    TISInputSource *obj = [[self alloc] initWithRef:ref];
    CFRelease(ref);
    return obj;
}

+ (BOOL)setInputMethodKeyboardLayoutOverride:(TISInputSource *)source
                                      error:(NSError * _Nullable * _Nullable)error {
    OSStatus err = TISSetInputMethodKeyboardLayoutOverride(source->_ref);
    if (err != noErr) {
        if (error != NULL) {
            *error = [TISInputSourceError errorWithCode:err];
        }
        return NO;
    }
    return YES;
}

+ (TISInputSource * _Nullable)inputMethodKeyboardLayoutOverride {
    TISInputSourceRef ref = TISCopyInputMethodKeyboardLayoutOverride();
    if (ref == nil) {
        return nil;
    }
    TISInputSource *obj = [[self alloc] initWithRef:ref];
    CFRelease(ref);
    return obj;
}

@end

NS_ASSUME_NONNULL_END
