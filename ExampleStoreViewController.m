/*****************************************************************************
 *
 * FILE:	ExampleStoreViewController.m
 * DESCRIPTION:	MagickWorX: Example view controller for In-App Purchase
 * DATE:	Tue, Nov 29 2011
 * UPDATED:	Wed, Dec  7 2011
 * AUTHOR:	Kouichi ABE (WALL) / 阿部康一
 * E-MAIL:	kouichi@MagickWorX.COM
 * URL:		http://www.MagickWorX.COM/
 * COPYRIGHT:	(c) 2011 阿部康一／Kouichi ABE (WALL), All rights reserved.
 * LICENSE:
 *
 *  Copyright (c) 2011 Kouichi ABE (WALL) <kouichi@MagickWorX.COM>,
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 *   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
 *   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *   INTERRUPTION)  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 *   THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: ExampleStoreViewController.m,v 1.3 2011/12/07 19:01:24 kouichi Exp $
 *
 *****************************************************************************/

#import "ExampleStoreViewController.h"
#import "MWXKeychainSuite.h"

#define	kDefaultTableCellIdentifier	@"StoreTableViewCellIdentifier"
#define	kDefaultRowHeight		68.0
#define	kDefaultHeaderHeight		36.0

#define	kNumberOfSections	1
#define	kSectionMain		0

@interface ExampleStoreViewController ()
@property (nonatomic,retain) MWXStoreManager *	storeManager;
@property (nonatomic,retain) NSSet *		productIds;
@property (nonatomic,retain) NSArray *		products;
@property (nonatomic,assign) MWXKeychainSuite *	keychainSuite;
@end

@interface ExampleStoreViewController (Private)
-(void)makeProductIds;
@end

@implementation ExampleStoreViewController

@synthesize	storeManager	= _storeManager;
@synthesize	productIds	= _productIds;
@synthesize	products	= _products;
@synthesize	keychainSuite	= _keychainSuite;

-(id)init
{
  self = [super init];
  if (self != nil) {
    // this title will appear in the navigation bar
    self.title		= NSLocalizedString(@"Store", @"");
    self.products	= nil;
    self.keychainSuite	= [MWXKeychainSuite sharedInstance];
  }
  return self;
}

-(void)dealloc
{
  [_storeManager release];
  [_productIds release];
  [_products release];
  [super dealloc];
}

-(void)didReceiveMemoryWarning
{
  /*
   * Invoke super's implementation to do the Right Thing,
   * but also release the input controller since we can do that.
   * In practice this is unlikely to be used in this application,
   * and it would be of little benefit,
   * but the principle is the important thing.
   */
  [super didReceiveMemoryWarning];
}

-(void)viewDidLoad
{
  [super viewDidLoad];

  CGRect	frame = self.view.bounds;
  frame.size.height  -= [[self navigationController]
			 navigationBar].bounds.size.height;

  UITableView *	tableView;
  tableView = [[UITableView alloc]
		initWithFrame:frame style:UITableViewStyleGrouped];
  tableView.delegate		= self;
  tableView.dataSource		= self;
  tableView.scrollEnabled	= YES;
  self.tableView		= tableView;
  [tableView release];


  UIBarButtonItem *	restoreButton;
  restoreButton = [[UIBarButtonItem alloc]
		    initWithTitle:NSLocalizedString(@"Restore", @"")
		    style:UIBarButtonItemStylePlain
		    target:self
		    action:@selector(restoreAction:)];
  self.navigationItem.leftBarButtonItem = restoreButton;
  [restoreButton release];

  UIBarButtonItem *	doneButton;
  doneButton = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemDone
		target:self
		action:@selector(doneAction:)];
  self.navigationItem.rightBarButtonItem = doneButton;
  [doneButton release];


  MWXStoreManager *	storeManager;
  storeManager = [[MWXStoreManager alloc] init];
  [storeManager setDelegate:self];
  self.storeManager = storeManager;
  [storeManager release];

  [self makeProductIds];
}

-(void)viewDidUnload
{
  self.storeManager	= nil;
  self.productIds	= nil;
  self.products		= nil;
  [super viewDidUnload];
}

-(void)viewDidAppear:(BOOL)animated
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  /*
   * XXX: Call the HUD indicator if you need.
   *
   * dispatch_async(dispatch_get_main_queue(), ^{
   *   [self.hud showInView:self.view.window];
   * });
   *
   */
  [self.storeManager requestProductDataForProductIds:self.productIds];
}

/*****************************************************************************/

-(void)makeProductIds
{
  NSString *	bundleId = [[NSBundle mainBundle] bundleIdentifier];
  NSArray *	items = [NSArray arrayWithObjects:
				@"removeAds",
				@"extensionPack1",
				@"extensionPack2",
				@"extensionPack3",
				nil];
  NSMutableSet *	productIds = [[NSMutableSet alloc] init];
  for (NSString * item in items) {
    [productIds addObject:[bundleId stringByAppendingString:item]];
  }
  self.productIds = productIds;
  [productIds release];
}

#pragma mark MWXStoreManagerDelegate
-(void)storeManager:(MWXStoreManager *)storeManager
	didReceiveListOfProducts:(NSArray *)products
{
  self.products = products;

  [self.tableView reloadData];

  /*
   * XXX: Stop the HUD
   *
   * dispatch_async(dispatch_get_main_queue(), ^{
   *   if ([self.hud isShowing]) {
   *     [self.hud dismiss];
   *   }
   * });
   */
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

/*****************************************************************************/

#pragma mark UIBarButtonItem action
-(void)doneAction:(id)sender
{
  [self.navigationController dismissViewControllerAnimated:YES
			     completion:^(){}];
}

#pragma mark UIBarButtonItem action
-(void)restoreAction:(id)sender
{
  UIAlertView *	alertView;
  alertView = [[UIAlertView alloc]
		initWithTitle:NSLocalizedString(@"Confirmation", @"")
		message:NSLocalizedString(@"RestoreProducts", @"")
		delegate:self
		cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
		otherButtonTitles:NSLocalizedString(@"Restore", @""), nil];
  [alertView show];
  [alertView release];
}

#pragma mark UIAlertViewDelegate
/*
 * Called when a button is clicked. The view will be automatically dismissed
 * after this call returns
 */
-(void)alertView:(UIAlertView *)alertView
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex != alertView.cancelButtonIndex) {
    [self.storeManager restoreProducts];
  }
}

/*****************************************************************************/

#pragma mark UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return self.products.count;
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView
	numberOfRowsInSection:(NSInteger)section
{
  return 1;
}

#pragma mark UITableViewDataSource
-(NSString *)tableView:(UITableView *)tableView
	titleForHeaderInSection:(NSInteger)section
{
  SKProduct *	product = [self.products objectAtIndex:section];

  return product.localizedTitle;
}

#pragma mark UITableViewDataSource
-(UITableViewCell *)tableView:(UITableView *)tableView
	cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger		section	= indexPath.section;
  SKProduct *		product	= [self.products objectAtIndex:section];
  UITableViewCell *	cell;

  cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:kDefaultTableCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc]
	    initWithStyle:UITableViewCellStyleSubtitle
	    reuseIdentifier:kDefaultTableCellIdentifier];
    [cell autorelease];
  }

  cell.textLabel.lineBreakMode	= UILineBreakModeWordWrap;
  cell.textLabel.numberOfLines	= 3;
  cell.textLabel.font		= [UIFont boldSystemFontOfSize:14.0];
  cell.textLabel.text		= product.localizedDescription;

  cell.detailTextLabel.textAlignment	= UITextAlignmentRight;
  cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:16.0];

  NSString *	productId = product.productIdentifier;
  if ([self.keychainSuite containsObjectForKey:productId]) {
    cell.accessoryType	= UITableViewCellAccessoryCheckmark;
    cell.selectionStyle	= UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.textColor	= [UIColor redColor];
    cell.detailTextLabel.text = NSLocalizedString(@"Purchased", @"");
  }
  else {
    cell.accessoryType	= UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle	= UITableViewCellSelectionStyleBlue;
    cell.detailTextLabel.textColor	= [UIColor blackColor];

    NSNumberFormatter *	formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
    cell.detailTextLabel.text = [formatter stringFromNumber:product.price];
    [formatter release];
  }

  return cell;
}


#pragma mark UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView
	heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return kDefaultRowHeight;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView
	didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

  NSInteger	section	= indexPath.section;
  SKProduct *	product = [self.products objectAtIndex:section];

  if (![self.keychainSuite containsObjectForKey:product.productIdentifier]) {
    [self.storeManager paymentWithProduct:product];
  }
}

/*****************************************************************************/

-(void)purchasing:(BOOL)purchasing
{
  self.view.userInteractionEnabled = !purchasing;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = purchasing;
}

-(void)recordTransaction:(SKPaymentTransaction *)transaction
{
  NSData *	receipt	  = [transaction transactionReceipt];
  SKPayment *	payment	  = [transaction payment];
  NSString *	productId = [payment productIdentifier];

#if	ENABLE_VERIFY_RECEIPT
  if ([self.storeManager verifyReceipt:receipt]) {
#if	DEBUG_STORE
    NSString *	sval = [[NSString alloc]
			initWithData:receipt encoding:NSUTF8StringEncoding];
    NSLog(@"DEBUG[verify] receipt=%@", sval);
    [sval release];
#endif	// DEBUG_STORE
    if ([self.productIds containsObject:productId]) {
      [self.keychainSuite setObject:receipt forKey:productId];
      [self.keychainSuite synchronize];
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Attention", @"")
		       message:NSLocalizedString(@"FinishedPurchasing", @"")];
      [self.tableView reloadData];
    }
  }
#else
  if ([self.productIds containsObject:productId]) {
    [self.keychainSuite setObject:receipt forKey:productId];
    [self.keychainSuite synchronize];
    [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Attention", @"")
		     message:NSLocalizedString(@"FinishedPurchasing", @"")];
    [self.tableView reloadData];
  }
#endif	// ENABLE_VERIFY_RECEIPT

  [self purchasing:NO];
}

#pragma mark MWXStoreManagerDelegate
-(void)storeManager:(MWXStoreManager *)storeManager
	didBeginTransaction:(SKPaymentTransaction *)transaction
{
  [self purchasing:YES];
}

#pragma mark MWXStoreManagerDelegate
-(void)storeManager:(MWXStoreManager *)storeManager
	didFailTransaction:(SKPaymentTransaction *)transaction
{
  [self purchasing:NO];
}

#pragma mark MWXStoreManagerDelegate
-(void)storeManager:(MWXStoreManager *)storeManager
	didCompleteTransaction:(SKPaymentTransaction *)transaction
{
  [self recordTransaction:transaction];
}

#pragma mark MWXStoreManagerDelegate
-(void)storeManager:(MWXStoreManager *)storeManager
	didCompleteRestoreTransaction:(SKPaymentTransaction *)transaction
{
  if (transaction.originalTransaction.transactionReceipt) {
    [self recordTransaction:transaction.originalTransaction];
  }
  else {
    [self recordTransaction:transaction];
  }
}

@end
