//
//  SGPageView.m
//  opera
//
//  Created by Single on 16/6/11.
//  Copyright © 2016年 HL. All rights reserved.
//

#import "SGPageView.h"

@interface SGPageTitleView ()

@property (nonatomic, weak) SGPageView * pageView;

- (void)reloadData;
- (void)scrollToIndex:(NSInteger)index;
- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated;

@end

@interface SGPageView () <UIScrollViewDelegate>

{
    dispatch_once_t _loadDataToken;
}

@property (nonatomic, strong) UIScrollView * scrollView;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) NSInteger numberOfPage;
@property (nonatomic, strong) NSArray <UIView *> * pages;
@property (nonatomic, strong) SGPageTitleView * pageTitleView;

@end

@implementation SGPageView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self UILayout];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self UILayout];
    }
    return self;
}

- (void)UILayout
{
    self.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.scrollView];
}

- (void)scrollToIndex:(NSInteger)index
{
    [self scrollToIndex:index animated:YES];
}

- (void)scrollToIndex:(NSInteger)index animated:(BOOL)animated
{
    self.index = index;
    CGFloat x = index * CGRectGetWidth(self.bounds);
    if ((x != self.scrollView.contentOffset.x) && (self.scrollView.contentSize.width > x)) {
        [self.scrollView setContentOffset:CGPointMake(x, 0) animated:animated];
    }
}

- (void)reloadData
{
    [self prepareData];
    [self resetLayout];
    [self.pageTitleView reloadData];
}

- (void)prepareData
{
    [self.pages enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    self.pages = nil;
    [self.pageTitleView removeFromSuperview];
    
    self.numberOfPage = [self.delegate numberOfPagesInPageView:self];
    NSMutableArray <UIView *> * pagesTemp = [NSMutableArray arrayWithCapacity:self.numberOfPage];
    for (NSInteger i = 0; i < self.numberOfPage; i++) {
        UIView * view = [self.delegate pageView:self viewAtIndex:i];
        [pagesTemp addObject:view];
        [self.scrollView ad dSubview:view];
    }
    self.pages = pagesTemp;
    self.index = self.defaultIndex;
    
    if ([self.delegate respondsToSelector:@selector(pageTitleViewInPageView:)]) {
        self.pageTitleView = [self.delegate pageTitleViewInPageView:self];
        self.pageTitleView.pageView = self;
    }
}

- (void)resetLayout
{
    self.scrollView.frame = self.bounds;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.bounds) * self.numberOfPage, CGRectGetHeight(self.bounds));
    
    [self.pages enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.frame = CGRectMake(idx * CGRectGetWidth(self.bounds), 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    }];
    
    self.scrollView.contentOffset = CGPointMake(self.index * CGRectGetWidth(self.bounds), 0);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self resetLayout];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self didEndScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self didEndScroll];
}

- (void)didEndScroll
{
    self.index = self.scrollView.contentOffset.x / self.scrollView.frame.size.width;
}

- (void)setIndex:(NSInteger)index
{
    if (_index != index) {
        _index = index;
        if (self.numberOfPage > index || [self.delegate respondsToSelector:@selector(pageView:didScrollToIndex:)]) {
            [self.delegate pageView:self didScrollToIndex:index];
            [self.pageTitleView scrollToIndex:index];
        }
    }
}

- (UIScrollView *)scrollView
{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.bounces = NO;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.directionalLockEnabled = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (point.x < 20 && self.scrollView.contentOffset.x == 0) {
        return self;
    }
    return [super hitTest:point withEvent:event];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    dispatch_once(&_loadDataToken, ^{
        [self reloadData];
    });
}

@end
