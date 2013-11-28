/* Return the canonical absolute name of a given string.
   Copyright (C) 1996-2013 Free Software Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.
  
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
   GNU General Public License for more details.
  
   You should have received a copy of the GNU General Public License
   along with this program. If not, see <http://www.gnu.org/licenses/>. */

#include <stdlib.h>
#include <stdio.h>

#include "vrt.h"
#include "bin/varnishd/cache.h"

#include "vcc_if.h"

const char *
vmod_canonicalize(struct sess *sp, const char *name)
{
  char *rname, *dest;
  char const *start;
  char const *end;

  unsigned u, v;

  if (name == NULL)
    return NULL;

  if (name[0] == '\0')
    return NULL;

  rname = WS_Alloc(sp->wrk->ws, sizeof(name));
  if (rname == NULL)
    return NULL;

  dest = rname;
  *dest++ = '/';
  start = name;

  for ( ; *start; start = end) {
    /* Skip sequence of multiple file name separators. */
    while ( *start == '/' )
      ++start;

    /* Find end of component. */
    for (end = start; *end && *end != '/'; ++end)
      /* Nothing. */;

    if (end - start == 1 && start[0] == '.')
      /* nothing */;
    else if (end - start == 2 && start[0] == '.' && start[1] == '.') {
      /* Back up to previous component, ignore if at root already. */
      if (dest > rname + 1)
        for (--dest; dest > rname && dest[-1] != '/'; --dest)
          continue;
    }
    else {
      if (dest[-1] != '/')
        *dest++ = '/';

      sprintf (dest, "%s", start);
      dest += end - start;
      *dest = '\0';
    }
  }

  return rname;

}
