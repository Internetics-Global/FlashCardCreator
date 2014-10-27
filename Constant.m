//
//  Constant.m
//  FlashCardCreator
//
//  Created by Bourne Wang on 5/23/14.
//  Copyright (c) 2014 Internetics. All rights reserved.
//

#import "Constant.h"

#ifdef DEBUG
int const ddLogLevel = LOG_LEVEL_VERBOSE;
#else
int const ddLogLevel = LOG_LEVEL_ERROR;
#endif