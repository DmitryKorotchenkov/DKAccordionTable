//
// Created by Dmitry Korotchenkov on 25/11/14.
// Copyright (c) 2014 Progress Engine. All rights reserved.
//

#import "DKAccordionTable.h"
#import "DKAccordionTableDataElement.h"

#define PERFORM_DELEGATE_SELECTOR(selector) \
if (self.accordionDelegate && [self.accordionDelegate respondsToSelector:_cmd]) {\
    return [self.accordionDelegate selector];\
}

@interface DKAccordionTable () <UIScrollViewDelegate>
// array of nodes indexes
@property(nonatomic, strong) NSArray *selectedNodePath;
@property(nonatomic, strong) NSArray *data;
@end

@implementation DKAccordionTable

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self setDataSourceAndDelegate];
    }

    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setDataSourceAndDelegate];
}

- (void)setDataSourceAndDelegate {
    [super setDataSource:self];
    [super setDelegate:self];
}

- (void)updateTableWithNewData:(NSArray *)data {
    self.data = data;
    self.selectedNodePath = nil;
}

- (void)setDataSource:(id <UITableViewDataSource>)dataSource {
    [super setDataSource:self];
}

- (void)setDelegate:(id <UITableViewDelegate>)delegate {
    [super setDelegate:self];
}


#pragma mark !!!!!!!!

- (BOOL)isNodePath:(NSArray *)nodePath containsSubPath:(NSArray *)subPath {
    if (nodePath.count >= subPath.count) {
        for (NSUInteger i = 0; i < subPath.count; i++) {
            NSNumber *baseNumber = nodePath[i];
            NSNumber *number = subPath[i];
            if (![baseNumber isEqualToNumber:number]) {
                return NO;
            }
        }
        return YES;
    }
    return NO;
}

- (NSUInteger)numberOfExpandedCellsInElements:(NSArray *)elements nodePath:(NSArray *)nodePath {
    if (nodePath.count > 0) {
        NSNumber *elementIndex = nodePath[0];
        DKAccordionTableDataElement *element = elements[elementIndex.unsignedIntegerValue];
        if (element.children) {
            if (nodePath.count > 1) {
                NSArray *subPath = [nodePath subarrayWithRange:NSMakeRange(1, nodePath.count - 1)];
                return element.children.count + [self numberOfExpandedCellsInElements:element.children nodePath:subPath];
            } else {
                return element.children.count;
            }
        }
    }
    return 0;
}

- (DKAccordionTableDataElement *)elementForNodePath:(NSArray *)path {
    return [self elementFromArray:self.data forPath:path];
}

- (DKAccordionTableDataElement *)elementFromArray:(NSArray *)elements forPath:(NSArray *)path {
    NSNumber *firstPathIndex = path[0];
    DKAccordionTableDataElement *element = elements[firstPathIndex.unsignedIntegerValue];
    if (path.count > 1) {
        NSArray *subPath = [path subarrayWithRange:NSMakeRange(1, path.count - 1)];
        return [self elementFromArray:element.children forPath:subPath];
    } else {
        return element;
    }
}

- (NSArray *)nodePathForIndexPath:(NSIndexPath *)indexPath {
    return [self nodePathForElements:self.data expandedPath:self.selectedNodePath index:indexPath.row];
}

- (NSMutableArray *)nodePathForElements:(NSArray *)elements expandedPath:(NSArray *)expandedPath index:(NSUInteger)index {
    if (expandedPath.count) {
        NSNumber *firstPathIndex = expandedPath[0];
        if (index > firstPathIndex.integerValue) {
            NSUInteger expandedCellsCount = [self numberOfExpandedCellsInElements:elements nodePath:expandedPath];
            if (index > firstPathIndex.integerValue + expandedCellsCount) {
                return @[@(index - expandedCellsCount)].mutableCopy;
            } else {
                DKAccordionTableDataElement *element = elements[firstPathIndex.unsignedIntegerValue];
                NSMutableArray *nodeSubPath;
                if (expandedPath.count > 1) {
                    NSArray *subPath = [expandedPath subarrayWithRange:NSMakeRange(1, expandedPath.count - 1)];
                    nodeSubPath = [self nodePathForElements:element.children expandedPath:subPath index:index - (firstPathIndex.integerValue + 1)];
                } else {
                    nodeSubPath = [self nodePathForElements:element.children expandedPath:nil index:index - (firstPathIndex.integerValue + 1)];
                }
                NSMutableArray *array = [@[firstPathIndex] mutableCopy];
                [array addObjectsFromArray:nodeSubPath];
                return array;
            }
        }
    }
    return @[@(index)].mutableCopy;
}

- (NSUInteger)indexForNodePath:(NSArray *)nodePath {
    NSUInteger index = 0;
    for (NSUInteger i = 0; i < nodePath.count; i++) {
        NSNumber *currentIndex = nodePath[i];
        index += currentIndex.integerValue;
    }
    return index + nodePath.count - 1;
}

- (NSArray *)nodePathForElement:(DKAccordionTableDataElement *)element {
    NSMutableArray *nodePath = [NSMutableArray new];
    NSArray *currentArray;
    DKAccordionTableDataElement *currentElement = element;
    do {
        currentArray = currentElement.parent ? currentElement.parent.children : self.data;
        [nodePath insertObject:@([currentArray indexOfObject:currentElement]) atIndex:0];
        currentElement = currentElement.parent;
    } while (currentElement);
    return nodePath;
}

- (void)reloadElement:(DKAccordionTableDataElement *)element {
    NSArray *nodePath = [self nodePathForElement:element];
    if ([[self elementForNodePath:nodePath] isEqual:element]) {
        [self reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self indexForNodePath:nodePath] inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UITableView delegate and dataSource methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *path = [self nodePathForIndexPath:indexPath];
    return [self.accordionDataSource tableView:tableView heightForRowWithElement:[self elementForNodePath:path]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger expandedCells = [self numberOfExpandedCellsInElements:self.data nodePath:self.selectedNodePath];
    return self.data.count + expandedCells;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *path = [self nodePathForIndexPath:indexPath];
    return [self.accordionDataSource tableView:tableView cellForElement:[self elementForNodePath:path]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *newSelectedPath = [self nodePathForIndexPath:indexPath];
    BOOL containsSubPath = [self isNodePath:self.selectedNodePath containsSubPath:newSelectedPath];
    if (containsSubPath) {
        if (newSelectedPath.count > 1) {
            newSelectedPath = [newSelectedPath subarrayWithRange:NSMakeRange(0, newSelectedPath.count - 1)];
        } else {
            newSelectedPath = nil;
        }
    } else {
        DKAccordionTableDataElement *selectedElement = [self elementForNodePath:newSelectedPath];
        if (selectedElement.children.count == 0) {
            [self tableView:tableView didSelectNonExpandableElement:selectedElement];
        }
    }
    [self updateTableView:tableView newSelectedPath:newSelectedPath];
}

- (void)updateTableView:(UITableView *)tableView newSelectedPath:(NSArray *)newSelectedPath {

    NSArray *commonSelectedIndexes = [NSArray new];
    for (NSUInteger i = 0; i < MIN(self.selectedNodePath.count, newSelectedPath.count); i++) {
        if ([self.selectedNodePath[i] isEqualToNumber:newSelectedPath[i]]) {
            commonSelectedIndexes = [newSelectedPath subarrayWithRange:NSMakeRange(0, i + 1)];
        } else {
            break;
        }
    }

    NSUInteger startIndexToDelete = 0;
    NSUInteger numbersOfRowsToDelete = 0;
    NSUInteger startIndexToInsert = 0;
    NSUInteger numbersOfRowsToInsert = 0;
    if (commonSelectedIndexes.count) {
        DKAccordionTableDataElement *commonElement = [self elementForNodePath:commonSelectedIndexes];
        NSArray *currentSelectionSubPath = [self.selectedNodePath subarrayWithRange:NSMakeRange(commonSelectedIndexes.count, self.selectedNodePath.count - commonSelectedIndexes.count)];
        if (currentSelectionSubPath.count) {
            startIndexToDelete = [self indexForNodePath:[commonSelectedIndexes arrayByAddingObject:currentSelectionSubPath.firstObject]] + 1;
            numbersOfRowsToDelete = [self numberOfExpandedCellsInElements:commonElement.children nodePath:currentSelectionSubPath];
        }

        NSArray *newSelectionSubPath = [newSelectedPath subarrayWithRange:NSMakeRange(commonSelectedIndexes.count, newSelectedPath.count - commonSelectedIndexes.count)];
        if (newSelectionSubPath.count) {
            startIndexToInsert = [self indexForNodePath:[commonSelectedIndexes arrayByAddingObject:newSelectionSubPath.firstObject]] + 1;
            numbersOfRowsToInsert = [self numberOfExpandedCellsInElements:commonElement.children nodePath:newSelectionSubPath];

        }
    } else {
        if (self.selectedNodePath.count) {
            startIndexToDelete = [self indexForNodePath:@[self.selectedNodePath[0]]] + 1;
            numbersOfRowsToDelete = [self numberOfExpandedCellsInElements:self.data nodePath:self.selectedNodePath];
        }
        if (newSelectedPath.count) {
            startIndexToInsert = [self indexForNodePath:@[newSelectedPath[0]]] + 1;
            numbersOfRowsToInsert = [self numberOfExpandedCellsInElements:self.data nodePath:newSelectedPath];
        }
    }

    NSMutableArray *indexPathsToUpdate = [NSMutableArray new];
    if (numbersOfRowsToDelete) {
        DKAccordionTableDataElement *element = [self elementForNodePath:[self nodePathForIndexPath:[NSIndexPath indexPathForRow:(startIndexToDelete - 1) inSection:0]]];
        if ([self tableView:tableView needReloadCellWhenCollapsingingForElement:element]) {
            [indexPathsToUpdate addObject:[NSIndexPath indexPathForRow:(startIndexToDelete - 1) inSection:0]];
        }
        [self tableView:tableView willCollapseExpandableElement:element];
    }
    if (numbersOfRowsToInsert) {
        DKAccordionTableDataElement *element = [self elementForNodePath:[self nodePathForIndexPath:[NSIndexPath indexPathForRow:(startIndexToInsert - 1) inSection:0]]];
        if ([self tableView:tableView needReloadCellWhenExpandingForElement:element]) {
            [indexPathsToUpdate addObject:[NSIndexPath indexPathForRow:(startIndexToInsert - 1) inSection:0]];
        }
        [self tableView:tableView willOpenExpandableElement:element];
    }


    [tableView beginUpdates];

    [tableView deleteRowsAtIndexPaths:[self indexPathsWithStartIndex:startIndexToDelete count:numbersOfRowsToDelete] withRowAnimation:UITableViewRowAnimationFade];
    [tableView insertRowsAtIndexPaths:[self indexPathsWithStartIndex:startIndexToInsert count:numbersOfRowsToInsert] withRowAnimation:UITableViewRowAnimationFade];
    [tableView reloadRowsAtIndexPaths:indexPathsToUpdate withRowAnimation:UITableViewRowAnimationAutomatic];
    self.selectedNodePath = newSelectedPath;
    [tableView endUpdates];
}

- (NSArray *)indexPathsWithStartIndex:(NSUInteger)index count:(NSUInteger)count {
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSUInteger i = index; i < index + count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    return indexPaths;
}

#pragma mark optional accordion dataSource methods

- (BOOL)tableView:(DKAccordionTable *)tableView needReloadCellWhenExpandingForElement:(DKAccordionTableDataElement *)element {
    if (self.accordionDataSource && [self.accordionDataSource respondsToSelector:@selector(tableView:needReloadCellWhenExpandingForElement:)]) {
        return [self.accordionDataSource tableView:tableView needReloadCellWhenExpandingForElement:element];
    }
    return NO;
}

- (BOOL)tableView:(DKAccordionTable *)tableView needReloadCellWhenCollapsingingForElement:(DKAccordionTableDataElement *)element {
    if (self.accordionDataSource && [self.accordionDataSource respondsToSelector:@selector(tableView:needReloadCellWhenCollapsingingForElement:)]) {
        return [self.accordionDataSource tableView:tableView needReloadCellWhenCollapsingingForElement:element];
    }
    return NO;
}

#pragma mark optional accordion delegate methods

- (void)tableView:(DKAccordionTable *)tableView didSelectNonExpandableElement:(DKAccordionTableDataElement *)element {
    if (self.accordionDelegate && [self.accordionDelegate respondsToSelector:@selector(tableView:didSelectNonExpandableElement:)]) {
        [self.accordionDelegate tableView:tableView didSelectNonExpandableElement:element];
    }
}

- (void)tableView:(DKAccordionTable *)tableView willOpenExpandableElement:(DKAccordionTableDataElement *)element {
    if (self.accordionDelegate && [self.accordionDelegate respondsToSelector:@selector(tableView:willOpenExpandableElement:)]) {
        [self.accordionDelegate tableView:tableView willOpenExpandableElement:element];
    }
}

- (void)tableView:(DKAccordionTable *)tableView willCollapseExpandableElement:(DKAccordionTableDataElement *)element {
    if (self.accordionDelegate && [self.accordionDelegate respondsToSelector:@selector(tableView:willCollapseExpandableElement:)]) {
        [self.accordionDelegate tableView:tableView willCollapseExpandableElement:element];
    }
}

@end