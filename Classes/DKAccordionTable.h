//
// Created by Dmitry Korotchenkov on 25/11/14.
// Copyright (c) 2014 Progress Engine. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DKAccordionTable;
@class DKAccordionTableDataElement;

@protocol DKAccordionTableDelegate

@optional
- (void)tableView:(DKAccordionTable *)tableView didSelectNonExpandableElement:(DKAccordionTableDataElement *)element;

- (void)tableView:(DKAccordionTable *)tableView willOpenExpandableElement:(DKAccordionTableDataElement *)element;

- (void)tableView:(DKAccordionTable *)tableView willCollapseExpandableElement:(DKAccordionTableDataElement *)element;

@end

@protocol DKAccordionTableDataSource
- (UITableViewCell *)tableView:(DKAccordionTable *)tableView cellForElement:(DKAccordionTableDataElement *)element;

- (CGFloat)tableView:(DKAccordionTable *)tableView heightForRowWithElement:(DKAccordionTableDataElement *)element;

@optional
- (BOOL)tableView:(DKAccordionTable *)tableView needReloadCellWhenExpandingForElement:(DKAccordionTableDataElement *)element;

- (BOOL)tableView:(DKAccordionTable *)tableView needReloadCellWhenCollapsingingForElement:(DKAccordionTableDataElement *)element;
@end

@interface DKAccordionTable : UITableView <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, weak) NSObject <DKAccordionTableDataSource> *accordionDataSource;
@property(nonatomic, weak) NSObject <DKAccordionTableDelegate> *accordionDelegate;

- (void)updateTableWithNewData:(NSArray *)data;

- (void)reloadElement:(DKAccordionTableDataElement *)element;
@end