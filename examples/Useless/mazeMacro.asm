; Contents of this file use a different licence as compared to the main project, specifically: CC BY-SA 4.0 -- [https://creativecommons.org/licenses/by-sa/4.0/]

.macro getChance percent
	.if \#{randomInt, 0, 100} < \%{percent} ; produce a #random number and check it against %percent
		.let chance = true ; output true if less than %percent
	.else
		.let chance = false ; or false if greater
	.endif
.endm

.let loopCount = 0 ; init loop counter
.let __ignoreMacroRecreate = true ; don't output the warning that a macro was overwritten

.begin
	.if \&{loopCount} < 32 ; do slashes for half the output, and bars/underlines for the other half
		.macro maze
			.let macroLoop = 0 ; init macroLoop
			.let mazeOut = \#{stripStr, ""} ; clear mazeOut
			.begin
				getChance 50 ; 50% chance of being true
				.if \&{chance} == true
					.let mazeOut += \#{backslash} ; append a backslash to maze out
				.else
					.let mazeOut += / ; append a forwardslash to maze out
				.endif
				.let macroLoop ++ ; make sure to increment loop counter!
			.until \&{macroLoop} >= 32 ; loop 32 times
			\&{mazeOut} ; output the produced line
		.endm
	.else
		.macro maze
			.let macroLoop = 0 ; init macroLoop
			.let mazeOut = \#{stripStr, ""} ; clear mazeOut
			.begin
				getChance 25 ; 25% chance of being true
				.if \&{chance} == true
					.let mazeOut += | ; append a bar to maze out
				.else
					.let mazeOut += _ ; append a underline to maze out
				.endif
				.let macroLoop ++ ; make sure to increment loop counter!
			.until \&{macroLoop} >= 32 ; loop 32 times
			\&{mazeOut} ; output the produced line
		.endm
	.endif
	maze ; run whichever maze macro was created
	.let loopCount ++ ; make sure to increment loop counter!
.until \&{loopCount} >= 64 ; loop 64 times