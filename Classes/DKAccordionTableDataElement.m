//
// Created by Dmitry Korotchenkov on 25/11/14.
// Copyright (c) 2014 Progress Engine. All rights reserved.
//

#import "DKAccordionTableDataElement.h"


@interface DKAccordionTableDataElement ()
@property(nonatomic, strong) NSMutableArray *children;
@end

@implementation DKAccordionTableDataElement

- (instancetype)initWithUserData:(id)userData {
    self = [super init];
    if (self) {
        self.userData = userData;
        self.children = [NSMutableArray new];
    }

    return self;
}

+ (instancetype)elementWithUserData:(id)userData {
    return [[self alloc] initWithUserData:userData];
}


- (void)addChild:(DKAccordionTableDataElement *)child {
    child.parent = self;
    [self.children addObject:child];
}

- (void)insertChild:(DKAccordionTableDataElement *)child atIndex:(NSUInteger)index {
    child.parent = self;
    [self.children insertObject:child atIndex:index];
}

- (void)removeChild:(DKAccordionTableDataElement *)child {
    [self.children removeObject:child];
}

- (void)replaceChildAtIndex:(NSUInteger)index withChild:(DKAccordionTableDataElement *)child {
    if (index < self.children.count) {
        [self removeChild:self.children[index]];
        [self insertChild:child atIndex:index];
    }
}

@end