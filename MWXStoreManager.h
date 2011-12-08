/*****************************************************************************
 *
 * FILE:	MWXStoreManager.h
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
 * $Id: MWXStoreManager.h,v 1.3 2011/12/07 19:01:24 kouichi Exp $
 *
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol MWXStoreManagerDelegate;

@interface MWXStoreManager : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
@private
  id <MWXStoreManagerDelegate>	_delegate;
}

@property (nonatomic,assign) id <MWXStoreManagerDelegate>	delegate;

// Convenient class method
+(void)popupViewWithTitle:(NSString *)title message:(NSString *)message;

+(BOOL)canOpenStore;

-(void)requestProductDataForProductIds:(NSSet *)productIds;

-(void)paymentWithProduct:(SKProduct *)product;

-(BOOL)verifyReceipt:(NSData *)receipt;

-(void)restoreProducts;

@end

@protocol MWXStoreManagerDelegate <NSObject>
@required
-(void)storeManager:(MWXStoreManager *)storeManager didReceiveListOfProducts:(NSArray *)products;
@optional
-(void)storeManager:(MWXStoreManager *)storeManager didBeginTransaction:(SKPaymentTransaction *)transaction;
-(void)storeManager:(MWXStoreManager *)storeManager didCompleteTransaction:(SKPaymentTransaction *)transaction;
-(void)storeManager:(MWXStoreManager *)storeManager didFailTransaction:(SKPaymentTransaction *)transaction;
-(void)storeManager:(MWXStoreManager *)storeManager didCompleteRestoreTransaction:(SKPaymentTransaction *)transaction;
@end
