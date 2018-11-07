/* UUCStringTable.cpp: implementation of the UUCStringTable class.
*
*  Copyright (c) 2000-2018 by Ugo Chirico - http://www.ugochirico.com
*  All Rights Reserved
*
*  This program is free software; you can redistribute it and/or modify
*  it under the terms of the GNU Lesser General Public License as published by
*  the Free Software Foundation; either version 2 of the License, or
*  (at your option) any later version.
*
*  This program is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software
*  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "UUCStringTable.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

UUCStringTable::UUCStringTable(int initialCapacity, float loadFactor)
: UUCHashtable<char*, char*>(initialCapacity, loadFactor)
{

}

UUCStringTable::UUCStringTable(int initialCapacity)
: UUCHashtable<char*, char*>(initialCapacity)
{

}

UUCStringTable::UUCStringTable()
{

}


UUCStringTable::~UUCStringTable()
{
	removeAll();
}

void UUCStringTable::put(char* const& szKey, char* const& szValue)
{
	char* szOldValue = NULL;
	char* szOldKey = szKey;

	char* szNewValue;
	char* szNewKey;

	if(containsKey(szKey))
	{
		get(szOldKey, szOldValue);
	}
	else
	{
		szOldKey = NULL;
	}
	
    size_t l1 = strlen(szValue);
	szNewValue = new char[l1 + 1];
	strlcpy(szNewValue, szValue, l1);

    size_t l2 = strlen(szKey);
	szNewKey = new char[l2 + 1];
	strlcpy(szNewKey, szKey, l2);

	UUCHashtable<char*, char*>::put(szNewKey, szNewValue);

	if(szOldKey)
		delete szOldKey;
	if(szOldValue)
		delete szOldValue;
}

unsigned long UUCStringTable::getHashValue(char* const& szKey) const
{
	return UUCStringTable::getHash((const char*)szKey); 
}

unsigned long UUCStringTable::getHash(const char* szKey)
{
	int h = 0;
	int off = 0;
	char* val = (char*)szKey;
	size_t len = strlen((char*)szKey);

	if (len < 16) 
	{
 	    for (unsigned long i = len ; i > 0; i--) 
		{
 			h = (h * 37) + val[off++];
 	    }
 	} 
	else 
	{
 	    // only sample some characters
 	    unsigned long skip = len / 8;
 	    for (unsigned long i = len ; i > 0; i -= skip, off += skip)
		{
 			h = (h * 39) + val[off];
 	    }
 	}

	return h;	
}

bool UUCStringTable::equal(char* const& szKey1, char* const& szKey2) const
{		
	return strcmp(szKey1,szKey2) == 0;
}

bool UUCStringTable::remove(char* const& szKey)
{
	char* szNewValue;

	char* szNewKey = szKey;;

	if(containsKey(szKey))
	{
		get(szNewKey, szNewValue);
		
		UUCHashtable<char*, char*>::remove(szNewKey);

		delete szNewKey;
		delete szNewValue;
		return true;
	}	

	return false;
}
