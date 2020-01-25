/* -*- tab-width: 4 -*- */

/*
  Copyright 2020 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
*/

package net.sourceforge.castleengine;

import android.Manifest;
import android.app.Activity;

public class ServiceWriteExternalStorage extends ServiceAbstract
{
    private static final String CATEGORY = "ServiceWriteExternalStorage";

    public ServiceWriteExternalStorage(MainActivity activity)
    {
        super(activity);
        getActivity().requestPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE);
    }

    public String getName()
    {
        return "write_external_storage";
    }
}
