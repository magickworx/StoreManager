/*****************************************************************************
 *
 * FILE:	MWXStoreManager.m
 * DESCRIPTION:	MagickWorX: In-App Purchase Management Class
 * DATE:	Sun, Oct 23 2011
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
 * $Id: MWXStoreManager.m,v 1.3 2011/12/07 19:01:24 kouichi Exp $
 *
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MWXStoreManager.h"

@interface MWXStoreManager ()
@end

@interface MWXStoreManager (Private)
-(void)completeTransaction:(SKPaymentTransaction *)transaction;
-(void)restoreTransaction:(SKPaymentTransaction *)transaction;
-(void)failedTransaction:(SKPaymentTransaction *)transaction;
-(NSString *)base64EncodedStringWithData:(NSData *)data;
@end

@implementation MWXStoreManager

@synthesize	delegate	= _delegate;

+(void)popupViewWithTitle:(NSString *)title message:(NSString *)message
{
  UIAlertView *	alertView;
  alertView = [[UIAlertView alloc]
		initWithTitle:title
		message:message
		delegate:nil
		cancelButtonTitle:NSLocalizedString(@"Close", @"")
		otherButtonTitles:nil];
  [alertView show];
  [alertView release];
}

+(BOOL)canOpenStore
{
  // アプリ内課金が許可されているか？
  if ([SKPaymentQueue canMakePayments]) {
    // ユーザに Store を表示
    return YES;
  }
  else {
    // ユーザに購入できない旨を通知
    [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Notice", @"")
		  message:NSLocalizedString(@"ForbidPurchasing", @"")];
    return NO;
  }
}

/*****************************************************************************/

-(id)init
{
  self = [super init];
  if (self != nil) {
    self.delegate   = nil;
  }
  return self;
}

-(void)dealloc
{
  [super dealloc];
}

/*****************************************************************************/

-(void)requestProductDataForProductIds:(NSSet *)productIds
{
  SKProductsRequest *	request;
  request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
  request.delegate = self;
  [request start];
}

#pragma mark SKProductsRequestDelegate
// Sent immediately before -requestDidFinish
-(void)productsRequest:(SKProductsRequest *)request
	didReceiveResponse:(SKProductsResponse *)response
{
  if (response != nil) {
    if (_delegate &&
	[_delegate respondsToSelector:@selector(storeManager:didReceiveListOfProducts:)]) {
      [_delegate storeManager:self
		 didReceiveListOfProducts:response.products];
    }

    if ([response.invalidProductIdentifiers count] > 0) {
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Error", @"")
		       message:NSLocalizedString(@"InvalidProductId", @"")];
#if	DEBUG
      // 確認できなかった Identifier を出力
      for (NSString * identifier in response.invalidProductIdentifiers) {
	NSLog(@"DEBUG[store] invalid product id: %@", identifier);
      }
#endif	// DEBUG
    }
  }
  [request autorelease];
}

/*****************************************************************************/

-(void)paymentWithProduct:(SKProduct *)product
{
  /*
   * Observers are not retained. The transactions array will only be
   * synchronized with the server while the queue has observers.
   * This may require that the user authenticate.
   */
  [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

  SKPayment *	payment = [SKPayment paymentWithProduct:product];
  /*
   * Asynchronous.
   * Add a payment to the server queue.  The payment is copied to add
   * an SKPaymentTransaction to the transactions array.  The same payment
   * can be added multiple times to create multiple transactions.
   */
  [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark SKPaymentTransactionObserver
/*
 * Sent when the transaction array has changed (additions or state changes).
 * Client should check state of transactions and finish as appropriate.
 */
-(void)paymentQueue:(SKPaymentQueue *)queue
	updatedTransactions:(NSArray *)transactions
{
  for (SKPaymentTransaction * transaction in transactions) {
    switch (transaction.transactionState) {
      // Transaction is being added to the server queue.
      case SKPaymentTransactionStatePurchasing:
	if (_delegate &&
	    [_delegate respondsToSelector:@selector(storeManager:didBeginTransaction:)]) {
	  [_delegate storeManager:self didBeginTransaction:transaction];
	}
	break;
      /*
       * Transaction is in queue, user has been charged.
       * Client should complete the transaction.
       */
      case SKPaymentTransactionStatePurchased:
	[self completeTransaction:transaction];
	break;
      /*
       * Transaction was cancelled or failed
       * before being added to the server queue.
       */
      case SKPaymentTransactionStateFailed:
	[self failedTransaction:transaction];
	break;
      /*
       * Transaction was restored from user's purchase history.
       * Client should complete the transaction.
       */
      case SKPaymentTransactionStateRestored:
	// Only valid if state is SKPaymentTransactionStateRestored.
	[self restoreTransaction:transaction];
	break;
    }
  }
}

-(void)completeTransaction:(SKPaymentTransaction *)transaction
{
  if (_delegate &&
      [_delegate respondsToSelector:@selector(storeManager:didCompleteTransaction:)]) {
    [_delegate storeManager:self didCompleteTransaction:transaction];
  }

  /*
   * Asynchronous.
   * Remove a finished (i.e. failed or completed) transaction from the queue.
   * Attempting to finish a purchasing transaction will throw an exception.
   */
  [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

-(void)restoreTransaction:(SKPaymentTransaction *)transaction
{
  if (_delegate &&
      [_delegate respondsToSelector:@selector(storeManager:didCompleteRestoreTransaction:)]) {
    [_delegate storeManager:self didCompleteRestoreTransaction:transaction];
  }

  /*
   * Asynchronous.
   * Remove a finished (i.e. failed or completed) transaction from the queue.
   * Attempting to finish a purchasing transaction will throw an exception.
   */
  [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

-(void)failedTransaction:(SKPaymentTransaction *)transaction
{
  if (_delegate &&
      [_delegate respondsToSelector:@selector(storeManager:didFailTransaction:)]) {
    [_delegate storeManager:self didFailTransaction:transaction];
  }

  // XXX: The following switch routine may be moved in _delegate if you want.
  NSError *	error = [transaction error];
  switch (transaction.error.code) {
    default:
    case SKErrorUnknown:
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Error", @"")
		       message:[error localizedDescription]];
      break;
    // client is not allowed to issue the request, etc.
    case SKErrorClientInvalid:
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Failed", @"")
		       message:[error localizedDescription]];
      break;
    // user cancelled the request, etc.
    case SKErrorPaymentCancelled:
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Cancelled", @"")
		       message:[error localizedDescription]];
      break;
    // purchase identifier was invalid, etc.
    case SKErrorPaymentInvalid:
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Failed", @"")
		       message:[error localizedDescription]];
      break;
    // this device is not allowed to make the paymen
    case SKErrorPaymentNotAllowed:
      [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Attention", @"")
		       message:[error localizedDescription]];
      break;
  }

  /*
   * Asynchronous.
   * Remove a finished (i.e. failed or completed) transaction from the queue.
   * Attempting to finish a purchasing transaction will throw an exception.
   */
  [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

/*****************************************************************************/

#if	DEBUG
#define	kVerifyReceiptURL	@"https://sandbox.itunes.apple.com/verifyReceipt"
#else
#define	kVerifyReceiptURL	@"https://buy.itunes.apple.com/verifyReceipt"
#endif	// DEBUG

-(BOOL)verifyReceipt:(NSData *)receipt
{
  BOOL	validated = NO;

  NSAutoreleasePool *	pool = [[NSAutoreleasePool alloc] init];

  NSURL *		url = [NSURL URLWithString:kVerifyReceiptURL];
  NSMutableURLRequest *	request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"POST"];

  NSString *	json = [NSString stringWithFormat:@"{\"receipt-data\" :\"%@\"}", [self base64EncodedStringWithData:receipt]];
  [request setHTTPBody:[json dataUsingEncoding:NSUTF8StringEncoding]];

  NSHTTPURLResponse *	response;
  NSError *		error;
  NSData *		data;
  data = [NSURLConnection sendSynchronousRequest:request
			  returningResponse:&response
			  error:&error];
  if ([response statusCode] == 200) {
    error = nil;
    NSDictionary *	dval;
    dval = [NSJSONSerialization JSONObjectWithData:data
				options:NSJSONReadingMutableContainers
				error:&error];
    if (!error) {
      NSInteger	status = [[dval objectForKey:@"status"] integerValue];
      validated = (status == 0);
    }
  }

  [pool drain];

  return validated;
}

// XXX: RFC4648 shows the algorithm and specification in detail.
-(NSString *)base64EncodedStringWithData:(NSData *)data
{
  static const char	base64[] =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

  const uint8_t *	s = (const uint8_t *)[data bytes];
  NSUInteger		l = [data length];
  NSMutableData *	o = [NSMutableData dataWithLength:(l * 4 / 3 + 4)];
  uint8_t *		p = (uint8_t *)o.mutableBytes;

  /*
   * encode 3-bytes (24-bits) at a time
   */
  NSUInteger	n = l - (l % 3);
  NSUInteger	i;
  NSUInteger	j;	// 最終的な文字列長が格納される
  for (i = j = 0; i < n; i += 3, j += 4) {
    p[j+0] = base64[( s[i+0] & 0xfc) >> 2];
    p[j+1] = base64[((s[i+0] & 0x03) << 4) | ((s[i+1] & 0xf0) >> 4)];
    p[j+2] = base64[((s[i+1] & 0x0f) << 2) | ((s[i+2] & 0xc0) >> 6)];
    p[j+3] = base64[( s[i+2] & 0x3f)];
  }

  i = n;	/* rest size */
  switch (l % 3) {
    case 2:	/* one character padding */
      p[j+0] = base64[( s[i+0] & 0xfc) >> 2];
      p[j+1] = base64[((s[i+0] & 0x03) << 4) | ((s[i+1] & 0xf0) >> 4)];
      p[j+2] = base64[( s[i+1] & 0x0f) << 2];
      p[j+3] = base64[64];	/* Pad	*/
      j += 4;
      break;
    case 1:	/* two character padding */
      p[j+0] = base64[(s[i] & 0xfc) >> 2];
      p[j+1] = base64[(s[i] & 0x03) << 4];
      p[j+2] = base64[64];	/* Pad	*/
      p[j+3] = base64[64];	/* Pad	*/
      j += 4;
      break;
    default:
      break;
  }
  p[j] = '\0';

  return [[[NSString alloc] initWithData:o encoding:NSASCIIStringEncoding]
	  autorelease];
}

/*****************************************************************************/

-(void)restoreProducts;
{
  /*
   * Observers are not retained.
   * The transactions array will only be synchronized with the server
   * while the queue has observers. This may require that the user authenticate.
   */
  [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

  /*
   * Asynchronous.
   * Will add completed transactions for the current user back to the queue
   * to be re-completed.  User will be asked to authenticate.  Observers will
   * receive 0 or more -paymentQueue:updatedTransactions:, followed by either
   * -paymentQueueRestoreCompletedTransactionsFinished: on success or
   * -paymentQueue:restoreCompletedTransactionsFailedWithError: on failure.
   * In the case of partial success, some transactions may still be delivered.
   */
  [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark SKPaymentTransactionObserver
// Sent when transactions are removed from the queue (via finishTransaction:).
-(void)paymentQueue:(SKPaymentQueue *)queue
	removedTransactions:(NSArray *)transactions
{
  /*
   * Array of unfinished SKPaymentTransactions.
   * Only valid while the queue has observers.  Updated asynchronously.
   */
  if (queue.transactions.count == 0) {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
  }
}

#pragma mark SKPaymentTransactionObserver
/*
 * Sent when an error is encountered while adding transactions
 * from the user's purchase history back to the queue.
 */
-(void)paymentQueue:(SKPaymentQueue *)queue
	restoreCompletedTransactionsFailedWithError:(NSError *)error
{
  [MWXStoreManager popupViewWithTitle:NSLocalizedString(@"Error", @"")
		   message:[error localizedDescription]];
}

#pragma mark SKPaymentTransactionObserver
/*
 * Sent when all transactions from the user's purchase history have successfully
 * been added back to the queue.
 */
-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
}

@end
