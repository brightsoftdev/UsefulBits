//
//  ESDoublePropertyMap.m
//	
//  Created by Doug Russell
//  Copyright (c) 2011 Doug Russell. All rights reserved.
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

#import "ESDoublePropertyMap.h"

@implementation ESDoublePropertyMap
@synthesize doubleTransformBlock=_doubleTransformBlock;

+ (id)newPropertyMapWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey doubleTransformBlock:(ESDoubleTransformBlock)doubleTransformBlock
{
	return [[[self class] alloc] initWithInputKey:inputKey outputKey:outputKey doubleTransformBlock:doubleTransformBlock];
}

- (id)initWithInputKey:(NSString *)inputKey outputKey:(NSString *)outputKey doubleTransformBlock:(ESDoubleTransformBlock)doubleTransformBlock
{
	self = [super initWithInputKey:inputKey outputKey:outputKey transformBlock:nil];
	if (self)
	{
		self.doubleTransformBlock = doubleTransformBlock;
	}
	return self;
}

@end
