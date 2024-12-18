    // // texture 0: noise  // RGBA= noise
    // // texture 1: noise  // RGBA= noise
    // // texture 2: offset // RGB= 0, A= offset
    // // texture 3: mask   // RGB= color mask, A= invert mask

    // // EXPAND(x) = 2*x-1
    // // HALF_BIAS(x) = X-0.5 

    // ---
    // // Stage 0: Pre-Plasma_stage

    // C0= {0, 0, $plasma_factor2}
    // C0a= $plasma_factor1

    // R0= INVERT(C0a)*T2a + C0a*T0a   // linear interpolation
    // R0a= INVERT(C0b)*1/2 + C0b*T1a  // T3/2 is accemptable
    		float pre_plasma0 = lerp(T2a, T0a, plasma_factor1); // R0
			float pre_plasma1 = lerp(0.5, T1a, plasma_factor2); // R0a

    // ---
    // // Stage 1: Preparation Stage

    // R0= T3a*1/2 + INVERT(T3a)*R0    // T3a/2
    // R0a= T3a*1/2 + INVERT(T3a)*R0a
			float masked_plasma0 = abs(T3a/2 + INVERT(T3a)*pre_plasma0); //R0
			float masked_plasma1 = abs(T3a/2 + INVERT(T3a)*pre_plasma1); // R0a

    // ---
    // // Stage 2: Half-Bias Stage

    // R0= R0 - HALF_BIAS(R0a)
    // R0a= R0a - HALF_BIAS(R0b)
			float plasma_intermed0 = abs(masked_plasma0 + HALF_BIAS_NEGATIVE(masked_plasma1)); // R0
			float mux_value = abs(masked_plasma1 + HALF_BIAS_NEGATIVE(masked_plasma0)); // R0a

    // ---
    // // Stage 3: Plasma Scale By 4 and Glow Stage

    // C0= $color_0.rgb
    // C0a= $color_0.a
    // C1= $color_1

    // #switch $glow_and_tint
    //     #case true
    //         D1= INVERT(C0a)*C0 + C0*C1 // linear interpolation
    //     #case false 
    //         D1= $color_1
    // #endswitch

    // R0a= OUT_SCALE_BY_4(R0a*R0a mux R0b*R0b)
			mux_value= MUX(mux_value, plasma_intermed0);
			mux_value= mux_value*mux_value*4;
    // ---
    // // Stage 4: Mask Attenuation and Plasma Sharpening Stage

    // T3= OUT_SCALE_BY_4(T3)				// Addresses visibility issues
    // R0a= 0 mux EXPAND(R0a)*EXPAND(R0a)
    		T3	=	4*T3;																// $plasma_factor3 is no longer used
			if(glow_and_tint)
			{
				T3 = 4*T3;
				T3 = color_0.rgb*T3;
			}
			float plasma_sharp= 	MUX(0, EXPAND(mux_value)); 							// R0a
			plasma_sharp*=	 plasma_sharp;

    // ---
    // // Stage 5: Mask Colorizing and Plasma Dulling stage

    // C0 = $color_0.rgb
    // #switch $glow_and_tint
    // 	#case true
    // 		T3= T3*C0
    // 	#case false
    // 		T3= T3;
    // 			#endswitch

    // R0a= R0a + R0a*INVERT(R0a)
    			float plasma_dull= plasma_sharp + plasma_sharp*INVERT(plasma_sharp); 		// R0a

    // ---
    // // Stage 6: Plasma Masking Stage

    // #switch $masked
    //     #case true
    //         R1= INVERT(T3a)
    //     #case false
    //         R1= T3
    // #endswitch

    // R0= R0a*T3 + D1*R1
    		float3 glow = lerp(color_0.rgb, color_1, color_0.a);
				   glow = glow_and_tint ? color_1 : glow;
		
			albedo.rgb= plasma_dull*T3 + glow*INVERT(T3a);
					if(masked){albedo.rgb= plasma_dull*T3 + glow*T3;}

    // ---
    // // Stage 7: Post-Processing Stage

    // C0a= $plasma_brightness
    // SRCCOLOR= R0*C0a
    // SRCALPHA= 0

    		albedo.rgb *= plasma_brightness;
			albedo.a= 0;
