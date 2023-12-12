/*
 * Copyright (c) 2022 Winsider Seminars & Solutions, Inc.  All rights reserved.
 *
 * This file is part of System Informer.
 *
 * Authors:
 *
 *     wj32
 *
 */

using System;

namespace GenerateZw
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            ArgumentNullException.ThrowIfNull(args);
            ZwGen.Execute();
        }
    }
}
