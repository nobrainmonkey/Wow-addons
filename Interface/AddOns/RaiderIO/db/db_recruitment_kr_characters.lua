--
-- Copyright (c) 2025 by RaiderIO, Inc.
-- All rights reserved.
--
local provider={name=...,data=3,region="kr",date="2025-09-17T08:28:55Z",numCharacters=35335,db={}}
local F

F = function() provider.db["헬스크림"]={0,"구사팽","홍탁기","후신타후"} end F()

F = nil
RaiderIO.AddProvider(provider)
