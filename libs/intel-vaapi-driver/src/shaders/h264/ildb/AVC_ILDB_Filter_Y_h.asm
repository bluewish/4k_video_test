/*
 * Copyright © <2010>, Intel Corporation.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sub license, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 * IN NO EVENT SHALL PRECISION INSIGHT AND/OR ITS SUPPLIERS BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * This file was originally licensed under the following license
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
////////// AVC ILDB filter horizontal Y ///////////////////////////////////////////////////////
//
//	This filter code prepares the src data and control data for ILDB filtering on all horizontal edges of Y.
//
//	It sssumes the data for horizontal de-blocking is already transposed.  
//
//		Luma:
//
//		+-------+-------+-------+-------+		H0  Edge
//		|		|		|		|		|
//		|		|		|		|		|
//		|		|		|		|		|
//		+-------+-------+-------+-------+		H1 Edge
//		|		|		|		|		|
//		|		|		|		|		|
//		|		|		|		|		|
//		+-------+-------+-------+-------+		H2	Edge
//		|		|		|		|		|
//		|		|		|		|		|
//		|		|		|		|		|
//		+-------+-------+-------+-------+		H3 Edge
//		|		|		|		|		|
//		|		|		|		|		|
//		|		|		|		|		|
//		+-------+-------+-------+-------+
//
/////////////////////////////////////////////////////////////////////////////

#if defined(_DEBUG) 
	mov		(1)		EntrySignatureC:w			0xBBBB:w
#endif	
	

//========== Luma deblocking ==========


//---------- Deblock Y external top edge (H0)  ----------	

	// Bypass deblocking if it is the top edge of the picture.  
	and.z.f0.0  (1) null:w		r[ECM_AddrReg, BitFlags]:ub		FilterTopMbEdgeFlag:w		// Check for FilterTopMbEdgeFlag 

//	and.z.f0.1 (1)	null:uw		r[ECM_AddrReg, wEdgeCntlMapA_ExtTopHorz0]:uw		0xFFFF:uw	// MaskA = 0? 

	// Get (alpha >> 2) + 2
	shr (1) alpha2:w		r[ECM_AddrReg, bAlphaTop0_Y]:ub		2:w			// alpha >> 2

	//	p3 = Prev MB Y row 0 = r[P_AddrReg, 0]<16;16,1> 
	//	p2 = Prev MB Y row 1 = r[P_AddrReg, 16]<16;16,1>
	//	p1 = Prev MB Y row 2 = r[P_AddrReg, 32]<16;16,1>
	//	p0 = Prev MB Y row 3 = r[P_AddrReg, 48]<16;16,1>
	// 	q0 = Cur MB Y row 0  = r[Q_AddrReg, 0]<16;16,1> 
	//	q1 = Cur MB Y row 1  = r[Q_AddrReg, 16]<16;16,1>
	//	q2 = Cur MB Y row 2  = r[Q_AddrReg, 32]<16;16,1>
	//	q3 = Cur MB Y row 3  = r[Q_AddrReg, 48]<16;16,1>
//	mov (1)	P_AddrReg:w		PREV_MB_Y_BASE:w		{ NoDDClr }
	mov (1)	P_AddrReg:w		TOP_MB_Y_BASE:w		{ NoDDClr }
	mov (1)	Q_AddrReg:w		SRC_MB_Y_BASE:w         { NoDDChk }
	
	// Get horizontal border edge control data
	// alpha = bAlphaTop0_Y 
	// beta = bBetaTop0_Y
	mov	(2)	alpha<1>:w	r[ECM_AddrReg, bAlphaTop0_Y]<2;2,1>:ub			{ NoDDClr }		// 2 channels for alpha and beta
	
	mov (2)	MaskA<1>:uw	r[ECM_AddrReg, wEdgeCntlMapA_ExtTopHorz0]<2;2,1>:uw		{ NoDDClr, NoDDChk }

	// tc0 has bTc0_h03_0_Y | bTc0_h02_0_Y | bTc0_h01_0_Y | bTc0_h00_0_Y
	mov (4)	tc0<1>:ub	r[ECM_AddrReg, bTc0_h00_0_Y]<4;4,1>:ub			{ NoDDChk }

//    (f0.0)	jmpi	BYPASS_EXT_TOP_EDGE_Y	
//	(f0.0.anyv)	 jmpi	BYPASS_EXT_TOP_EDGE_Y
	
	add (1) alpha2:w		alpha2:w		2:w								// alpha2 = (alpha >> 2) + 2  
		
//	CALL(FILTER_Y, 1)
	PRED_CALL(-f0.0, FILTER_Y, 1)

//BYPASS_EXT_TOP_EDGE_Y:
//------------------------------------------------------------------
	// Same alpha, alpha2, beta and MaskB for all internal edges 

	// Get (alpha >> 2) + 2
	shr (1) alpha2:w		r[ECM_AddrReg, bAlphaInternal_Y]:ub		2:w			// alpha >> 2

	// alpha = bAlphaInternal_Y 
	// beta = bBetaInternal_Y
	mov	(2)	alpha<1>:w	r[ECM_AddrReg, bAlphaInternal_Y]<2;2,1>:ub 		{ NoDDClr }

	// Set MaskB = 0 for all 3 int edges, so it always uses bS < 4 algorithm.
	mov (1) MaskB:uw	0:w						                        { NoDDChk }

	add (1) alpha2:w		alpha2:w		2:w								// alpha2 = (alpha >> 2) + 2  
		

//---------- Deblock Y internal top edge (H1)  ----------

	// Bypass deblocking if FilterInternal4x4EdgesFlag = 0  
	and.z.f0.0 (1) null:w	r[ECM_AddrReg, BitFlags]:ub		FilterInternal4x4EdgesFlag:w		// Check for FilterInternal4x4EdgesFlag 

	//	p3 = Cur MB Y row 0 = r[P_AddrReg, 0]<16;16,1> 
	//	p2 = Cur MB Y row 1 = r[P_AddrReg, 16]<16;16,1>
	//	p1 = Cur MB Y row 2 = r[P_AddrReg, 32]<16;16,1>
	//	p0 = Cur MB Y row 3 = r[P_AddrReg, 48]<16;16,1>
	// 	q0 = Cur MB Y row 4 = r[Q_AddrReg, 0]<16;16,1> 
	//	q1 = Cur MB Y row 5 = r[Q_AddrReg, 16]<16;16,1>
	//	q2 = Cur MB Y row 6 = r[Q_AddrReg, 32]<16;16,1>
	//	q3 = Cur MB Y row 7 = r[Q_AddrReg, 48]<16;16,1>
	mov (1)	P_AddrReg:w		SRC_MB_Y_BASE:w					{ NoDDClr }
	mov (1)	Q_AddrReg:w		4*Y_ROW_WIDTH+SRC_MB_Y_BASE:w   { NoDDChk }

	mov (1)	MaskA:uw	r[ECM_AddrReg, wEdgeCntlMap_IntTopHorz]:uw		{ NoDDClr }
	
	// tc0 has bTc0_h13_Y + bTc0_h12_Y + bTc0_h11_Y + bTc0_h10_Y		
	mov (4)	tc0<1>:ub	r[ECM_AddrReg, bTc0_h10_Y]<4;4,1>:ub			{ NoDDChk }

//    (f0.0)	jmpi	BYPASS_4x4_DEBLOCK_H
//	(f0.0.anyv)	 jmpi	BYPASS_4x4_DEBLOCK_H

//	CALL(FILTER_Y, 1)
	PRED_CALL(-f0.0, FILTER_Y, 1)

//BYPASS_4x4_DEBLOCK_H:
//------------------------------------------------------------------


//---------- Deblock Y internal mid horizontal edge (H2) ----------

	// Bypass deblocking if FilterInternal8x8EdgesFlag = 0  
	and.z.f0.0 (1) null:w	r[ECM_AddrReg, BitFlags]:ub		FilterInternal8x8EdgesFlag:w		// Check for FilterInternal4x4EdgesFlag 

//	and.z.f0.1 (1)	null:uw		r[ECM_AddrReg, wEdgeCntlMap_IntMidHorz]:uw		0xFFFF:uw	// MaskA = 0? 

	//	p3 = Cur MB Y row 4  = r[P_AddrReg, 0]<16;16,1> 
	//	p2 = Cur MB Y row 5  = r[P_AddrReg, 16]<16;16,1>
	//	p1 = Cur MB Y row 6  = r[P_AddrReg, 32]<16;16,1>
	//	p0 = Cur MB Y row 7  = r[P_AddrReg, 48]<16;16,1>
	// 	q0 = Cur MB Y row 8  = r[Q_AddrReg, 0]<16;16,1> 
	//	q1 = Cur MB Y row 9  = r[Q_AddrReg, 16]<16;16,1>
	//	q2 = Cur MB Y row 10 = r[Q_AddrReg, 32]<16;16,1>
	//	q3 = Cur MB Y row 11 = r[Q_AddrReg, 48]<16;16,1>
	mov (1)	P_AddrReg:w		4*Y_ROW_WIDTH+SRC_MB_Y_BASE:w      { NoDDClr }
	mov (1)	Q_AddrReg:w		8*Y_ROW_WIDTH+SRC_MB_Y_BASE:w      { NoDDChk }

	mov (1)	MaskA:uw	r[ECM_AddrReg, wEdgeCntlMap_IntMidHorz]:uw      { NoDDClr }
//	mov (1) MaskB:uw	0:w						// Set MaskB = 0, so it always uses bS < 4 algorithm.

	// tc0 has bTc0_h23_Y + bTc0_h22_Y + bTc0_h21_Y + bTc0_h20_Y		
	mov (4)	tc0<1>:ub	r[ECM_AddrReg, bTc0_h20_Y]<4;4,1>:ub			{ NoDDChk }

//    (f0.0)	jmpi	BYPASS_8x8_DEBLOCK_H
//	(f0.0.anyv)	 jmpi	BYPASS_8x8_DEBLOCK_H
   
//	CALL(FILTER_Y, 1)
	PRED_CALL(-f0.0, FILTER_Y, 1)

//BYPASS_8x8_DEBLOCK_H:
//-----------------------------------------------


//---------- Deblock Y internal bottom edge (H3) ----------	 

	// Bypass deblocking if FilterInternal4x4EdgesFlag = 0  
	and.z.f0.0 (1) null:w	r[ECM_AddrReg, BitFlags]:ub		FilterInternal4x4EdgesFlag:w		// Check for FilterInternal4x4EdgesFlag 

//	and.z.f0.1 (1)	null:uw		r[ECM_AddrReg, wEdgeCntlMap_IntBotHorz]:uw		0xFFFF:uw	// MaskA = 0? 

	//	p3 = Cur MB Y row 8  = r[P_AddrReg, 0]<16;16,1> 
	//	p2 = Cur MB Y row 9  = r[P_AddrReg, 16]<16;16,1>
	//	p1 = Cur MB Y row 10 = r[P_AddrReg, 32]<16;16,1>
	//	p0 = Cur MB Y row 11 = r[P_AddrReg, 48]<16;16,1>
	// 	q0 = Cur MB Y row 12 = r[Q_AddrReg, 0]<16;16,1> 
	//	q1 = Cur MB Y row 13 = r[Q_AddrReg, 16]<16;16,1>
	//	q2 = Cur MB Y row 14 = r[Q_AddrReg, 32]<16;16,1>
	//	q3 = Cur MB Y row 15 = r[Q_AddrReg, 48]<16;16,1>
	mov (1)	P_AddrReg:w		8*Y_ROW_WIDTH+SRC_MB_Y_BASE:w		{ NoDDClr } 
	mov (1)	Q_AddrReg:w		12*Y_ROW_WIDTH+SRC_MB_Y_BASE:w      { NoDDChk } 

	
	mov (1)	MaskA:uw	r[ECM_AddrReg, wEdgeCntlMap_IntBotHorz]:uw      { NoDDClr }
//	mov (1) MaskB:uw	0:w						// Set MaskB = 0, so it always uses bS < 4 algorithm.

	// tc0 has bTc0_h33_Y + bTc0_h32_Y + bTc0_h31_Y + bTc0_h30_Y         
	mov (4)	tc0<1>:ub	r[ECM_AddrReg, bTc0_h30_Y]<4;4,1>:ub			{ NoDDChk }

//    (f0.0)	jmpi	BYPASS_4x4_DEBLOCK_H2
//	(f0.0.anyv)	 jmpi	BYPASS_4x4_DEBLOCK_H2
    
//	CALL(FILTER_Y, 1)
	PRED_CALL(-f0.0, FILTER_Y, 1)

//BYPASS_4x4_DEBLOCK_H2:
//-----------------------------------------------
