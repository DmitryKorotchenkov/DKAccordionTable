//
// Created by Dmitry Korotchenkov on 25/11/14.
// Copyright (c) 2014 Progress Engine. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DKAccordionTableDataElement : NSObject

@property(nonatomic, strong) id userData;
@property(nonatomic, weak) DKAccordionTableDataElement *parent;
@property(nonatomic, strong, readonly) NSMutableArray *children;

- (instancetype)initWithUserData:(id)userData;

+ (instancetype)elementWithUserData:(id)userData;


- (void)addChild:(DKAccordionTableDataElement *)child;

- (void)insertChild:(DKAccordionTableDataElement *)child atIndex:(NSUInteger)index;

- (void)removeChild:(DKAccordionTableDataElement *)child;

- (void)replaceChildAtIndex:(NSUInteger)index withChild:(DKAccordionTableDataElement *)child;
@end