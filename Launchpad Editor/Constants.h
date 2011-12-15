//
//  Constants.h
//  Launchpad Editor
//
//  Created by David Deller on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifndef Launchpad_Editor_Constants_h
#define Launchpad_Editor_Constants_h

// There must be a better way to do this... Obj-C constants are very confusing
static NSString *const HNLaunchpadPasteboardType = @"HNLaunchpadPasteboardType";

static int const HNLaunchpadTypePage = 3;
static int const HNLaunchpadTypeGroup = 2;
static int const HNLaunchpadTypeApp = 4;

static int const HNLaunchpadHoldingPageId = 2;

static int const HNLaunchpadPageMaxItems = 40;
static int const HNLaunchpadGroupMaxItems = 32;

// Default value for 'flags' column in items table; I have no idea what this means
static int const HNLaunchpadDefaultFlags = 0;

// Temporary value for 'ordering' column when creating a new object; this should be fixed with HNLaunchpadDataSet -saveContainerOrdering:inDb:
static int const HNLaunchpadDefaultOrdering = -1;

// Value to use as parent ID for Page Entities
static int const HNLaunchpadPageParentId = 1;

// Maximum number of automatic backups to keep before deleting.
// The oldest automatic backup is always kept. Manual backups are always kept.
static int const HNLaunchpadMaxNumAutoBackups = 10;

#endif
